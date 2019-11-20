#!/usr/bin/perl -I../lib
use CGI::Carp 'fatalsToBrowser';
use CGI;  
use DBI;  
use def; 
use tools; 
use dm;

# use Data::Dumper;
# use def_handmade;

$dm_cfg{customtitle} = $migctrad{languages_title};

$dm_cfg{vis_opt} = 1;
$dm_cfg{sort_opt} = 0;

$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "migcms_languages";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_languages.pl?";

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
			add_db
			mod_db
			del_db
		);

if (is_in(@fcts,$sw)) { 
    dm_init();
    &$sw();
    print wfw_app_layout($dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}
