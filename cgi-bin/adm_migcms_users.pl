#!/usr/bin/perl -I../lib

use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm_publish_pdf;
use dm;
use JSON;
use HTML::Entities;   
use Unicode::MapUTF8 qw(to_utf8 from_utf8 utf8_supported_charset); 

#
#
#

$dm_cfg{excel_key} = 'id';
$dm_cfg{import_encode_entities} = 'y';


$dm_cfg{customtitle} = $fwtrad{users_title};
$dm_cfg{enable_search} = 1;
$dm_cfg{enable_multipage} = 1;

$dm_cfg{vis_opt} = 1;
$dm_cfg{sort_opt} = 0;
$dm_cfg{duplicate} = 1;
$dm_cfg{lock_on} = 0;
$dm_cfg{lock_off} = 0;
$dm_cfg{duplicate} = 1;
$dm_cfg{telecharger} = 0;
$dm_cfg{email} = 0;
$dm_cfg{viewpdf} = 0;
$dm_cfg{pdfzip} = 0;

$dm_cfg{table_name} = "users"; 
$stmt = "update $dm_cfg{table_name} SET id_language = 1 where id_language = 0";
execstmt($dbh,$stmt);


$dm_cfg{default_ordby} = "id_role asc, lastname, firstname";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_users.pl?";

my $where_role = " AND id >= $user{id_role}";
$dm_cfg{wherep} = $dm_cfg{wherel} =  " id_role >= $user{id_role}";

$dm_cfg{file_prefixe} = 'USR';

$dm_cfg{add_title} = $migctrad{adm_adduser};

@dm_nav = (
  {
    'tab'=>'infos',
    'type'=>'tab',
    'title'=>'Informations',
  },
  {
    'tab'=>'tab_prix',
    'type'=>'cgi_func',
    'cgi_func'=>\&authentification_google,
    'title'=>'Authentification Google',
  },


);

%dm_dfl = (
    '01/firstname'=> {
        'title'=>$migctrad{adm_firstname},
        'fieldtype'=>'text',
        'fieldsize'=>'40',
        'search' => 'y',
        'tab' => 'infos',
        'mandatory'=>{"type" => '',
                     }
    },
	'02/lastname'=> {
        'title'=>$migctrad{adm_lastname},
        'fieldtype'=>'text',
        'fieldsize'=>'40',
        'search' => 'y',
        'tab' => 'infos',
        'mandatory'=>{"type" => '',
                     }
    }
	,
	'03/initiales'=> {
        'title'=>$migctrad{initials},
        'fieldtype'=>'text',
        'fieldsize'=>'40',
        'search' => 'y',
        'tab' => 'infos',
        'mandatory'=>{"type" => '',
                     }
    }
	,
    '04/email'=> {
        'title'=>$migctrad{adm_email},
        'fieldtype'=>'text',
			'data_type'=>'email',
        'search' => 'y',
        'tab' => 'infos',
        'mandatory'=>{"type" => 'not_empty',
                     }
    },
    '05/password'=> {
        'title'=>$migctrad{adm_pwd},
        'fieldtype'=>'text',
		'data_type'=>'password',
    'tab' => 'infos',
    }
  ,
    '06/id_role'=> {
        'title'=>$migctrad{adm_role},
        'fieldtype'=>'listboxtable',
        'lbtable'=>'migcms_roles',
        'lbkey'=>'id',
        'lbdisplay'=>'nom_role',
        'lbwhere'=>"visible='y' $where_role",
        'tab' => 'infos',
        'mandatory'=>{"type" => 'not_empty',
                    }
	}
	 ,
    '07/id_language'=> {
        'title'=>$migctrad{adm_interface_langue},
        'fieldtype'=>'listboxtable',
        'lbtable'=>'migcms_languages',
        'lbkey'=>'id',
        'lbdisplay'=>'name',
        'lbwhere'=>"",
        'tab' => 'infos',
        'mandatory'=>{"type" => 'not_empty',
                    }
	}
	 ,
    '08/first_page_url'=> {
        'title'=>'URL accueil admin',
        'fieldtype'=>'text',
        'tab' => 'infos',
       }
	,
	'67/fichiers'=> 
	{
        'title'=>"Fichiers",
        'fieldtype'=>'files_admin',
		'disable_add'=>1,
    'tab' => 'infos',
    }
);


#     },
%dm_display_fields = (
    "1/$migctrad{adm_firstname}"=>"firstname",
	"2/$migctrad{adm_lastname}"=>"lastname",
	"3/$migctrad{adm_role}"=>"id_role",
	"4/$migctrad{adm_interface_langue}"=>"id_language",
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

google_linked_db
);


if (is_in(@fcts,$sw)) {
    dm_init();
    &$sw();
    $gen_bar = get_gen_buttonbar();
    $spec_bar = get_spec_buttonbar($sw);


    print wfw_app_layout($dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}


sub authentification_google
{

  my $dbh = $_[0];
  my $id = $_[1];

  return get_authentification_google({id_user=>$id});
}

