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

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###############################################################################################
####################################	CODE DU PROGRAMME		######################################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

my %user = %{get_user_info($dbh, $config{current_user})} or wfw_no_access();
$dm_cfg{customtitle} = $migctrad{languages_title};

my $htaccess_ssl = $config{rewrite_ssl};
my $htaccess_protocol_rewrite = "http";
if($htaccess_ssl eq 'y') {
  $htaccess_protocol_rewrite = "https";
}

$dm_cfg{enable_search} = 0;
$dm_cfg{enable_multipage} = 0;
$dm_cfg{vis_opt} = 1;
$dm_cfg{sort_opt} = 0;

$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "languages";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{get_form_ref} = \&get_form;
$dm_cfg{get_view_ref} = \&get_view;
$dm_cfg{get_and_check_ref} = \&get_and_check;
$dm_cfg{before_del_ref} = \&before_del;
$dm_cfg{table_width} = 800;
$dm_cfg{fieldset_width} = 950;
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_cmslg.pl?";

$config{logfile} = "trace.log";

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (
	    '01/name'=> {
	        'title'=>$migctrad{language_name},
	        'fieldtype'=>'text',
	        'fieldsize'=>'5',
	        'search' => 'n',
	        'mandatory'=>{"type" => 'not_empty'},
	    },
	    '02/display_name'=> {
	        'title'=>$migctrad{language_display_name},
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'n',
	        'mandatory'=>{"type" => 'not_empty'},
	    },
	    
	    '03/charset'=> {
	        'title'=>$migctrad{language_charset},
	        'fieldtype'=>'listbox',
          'fieldvalues'=>{
                 'ISO-8859-1'=>'ISO-8859-1',
                 'ISO-8859-2'=>'ISO-8859-2',
                 'ISO-8859-3'=>'ISO-8859-3',
                 'ISO-8859-4'=>'ISO-8859-4',
                 'ISO-8859-5'=>'ISO-8859-5',
                 'ISO-8859-6'=>'ISO-8859-6',
                 'ISO-8859-6-e'=>'ISO-8859-6-e',
                 'ISO-8859-6-i'=>'ISO-8859-6-i',
                 'ISO-8859-7'=>'ISO-8859-7',
                 'ISO-8859-8'=>'ISO-8859-8',
                 'ISO-8859-8-e'=>'ISO-8859-8-e',
                 'ISO-8859-8-i'=>'ISO-8859-8-i',
                 'ISO-8859-9'=>'ISO-8859-9',
                 'ISO-8859-10'=>'ISO-8859-10',
                 'ISO-8859-13'=>'ISO-8859-13',
                 'ISO-8859-14'=>'ISO-8859-14',
                 'ISO-8859-14'=>'ISO-8859-14',
                 'ISO-8859-15'=>'ISO-8859-15',
                 'UTF-8'=>'UTF-8',
                 'ISO-2022-JP'=>'ISO-2022-JP',
                 'EUC-JP'=>'EUC-JP',
                 'Shift_JIS'=>'Shift_JIS',
                 'GB2312'=>'GB2312',
                 'Big5'=>'Big5',
                 'EUC-KR'=>'EUC-KR',
                 'windows-1250'=>'windows-1250',
                 'windows-1251'=>'windows-1251',
                 'windows-1252'=>'windows-1252',
                 'windows-1253'=>'windows-1253',
                 'windows-1254'=>'windows-1254',
                 'windows-1255'=>'windows-1255',
                 'windows-1256'=>'windows-1256',
                 'windows-1257'=>'windows-1257',
                 'windows-1258'=>'windows-1258',
                 'KOI8-R'=>'KOI8-R',
                 'KOI8-U'=>'KOI8-U',
                 'cp866'=>'cp866',
                 'cp874'=>'cp874',
                 'TIS-620'=>'TIS-620',
                 'VISCII'=>'VISCII',
                 'VPS'=>'VPS',
                 'TCVN-5712'=>'TCVN-5712'
           }
	    }
      
      ,
'20/id_member_group'=> 
{
'title'=>'Groupe newsletter lié',
'fieldtype'=>'listboxtable',
'lbtable'=>'mailing_groups',
'lbkey'=>'id',
'lbdisplay'=>'title',
'lbwhere'=>""
}
,
      '30/encode_ok'=> 
      {
	        'title'=>'Pouvoir encoder le texte',
	        'fieldtype'=>'checkbox',
	        'checkedval' => 'y'
	    }
	    
	    
	    
	    
	    
	    
	);

%dm_display_fields = (
			"1/$migctrad{language_display_name}"=>"display_name",
			"2/$migctrad{language_name}"=>"name",
			"3/$migctrad{language_charset}"=>"charset",
      "4/Groupe newsletter lié"=>"id_member_group",
		);

%dm_lnk_fields = (
		);

%dm_mapping_list = (
);

%dm_filters = (
		);

$dm_cfg{help_url} = "http://www.bugiweb.com";
#$fwicons{"add"} = "<img src=\"gfx/icons/user_add.png\" />",
#$fwicons{"del"} = "<img src=\"gfx/icons/user_delete.png\" />",

# this script's name

$sw = $cgi->param('sw') || "list";

see();

my @fcts = qw(
			add_form
			mod_form
			list
			add_db
			mod_db
			del_db
		);

if (is_in(@fcts,$sw)) { 
    dm_init();
    &$sw();
    $gen_bar = get_gen_buttonbar();
    $spec_bar = get_spec_buttonbar($sw);
    print wfw_app_layout($dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub get_and_check
{
	my %item; 
  my $op = $_[0];
  
	foreach $key (keys(%dm_dfl))
	{ 
		my ($num,$field) = split(/\//,$key);
		$item{$field} = get_quoted($field);
		if (defined $dm_dfl{$key}{mandatory})
		{
			if (!check_field_value($item{$field}, $dm_dfl{$key}{mandatory}{type}, \@{$dm_dfl{$key}{mandatory}{params}}))
			{
				dm_check_error($dm_dfl{$key}{title});
			}
		}
  }

	return (\%item);	
}
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub get_form
{
	my %item = %{$_[0]};
	my $form = build_form(\%dm_dfl,\%item);

	return $form;
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
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------