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
$dm_cfg{after_add_ref} = \&after_save;
$dm_cfg{after_mod_ref} = \&after_save;


$dm_cfg{table_name} = "users"; 

$dm_cfg{default_ordby} = "lastname, firstname";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_handmade_migcms_users.pl?";

$dm_cfg{wherep} = $dm_cfg{wherel} =  " id_role IN ('7','8') and id != '25'";

$dm_cfg{file_prefixe} = 'USR';


@dm_nav = (
  {
    'tab'=>'infos',
    'type'=>'tab',
    'title'=>'Informations',
  },
  # {
    # 'tab'=>'tab_prix',
    # 'type'=>'cgi_func',
    # 'cgi_func'=>\&authentification_google,
    # 'title'=>'Authentification Google',
  # },


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
        'default_value'=>'8',
        'lbdisplay'=>'nom_role',
        'lbwhere'=>"visible='y' AND id IN ('7','8') ",
        'tab' => 'infos',
        'mandatory'=>{"type" => 'not_empty',
                    }
	}
    ,
    '07/api_key'=> {
        'title'=>'Clé API',
        'fieldtype'=>'text',
        'lbtable'=>'',
        'lbkey'=>'id',
        'default_value'=>'',
        'lbdisplay'=>'nom_role',
        'lbwhere'=>"visible='y' AND id IN ('7','8') ",
        'tab' => 'infos',
        'mandatory'=>{"type" => '',
                    }
	}
	 # ,
    # '66/acheteur'=> {
        # 'title'=>'Acheteur',
        # 'fieldtype'=>'checkbox',
        # 'tab' => 'infos',
		
                    # }
					 # ,
    # '76/vendeur'=> {
        # 'title'=>'Vendeur',
        # 'fieldtype'=>'checkbox',
        # 'tab' => 'infos',
		
                    # }
					# ,
	# '77/id_textid_fonction'=> 
	# {
	# 'title'=>'Fonction',
	# 'fieldtype'=>'text_id',
	# 'search' => 'y',
        # 'tab' => 'infos',
	
	# 'mandatory'=>{"type" => ''},
	# }
	# ,
	# '78/langues'=>{'title'=>'Langue(s)','multiple'=>1,'translate'=>1,'fieldtype'=>'listboxtable','data_type'=>'button','search' => 'n','mandatory'=>{"type" => ''},'tab'=>'infos','default_value'=>'','lbtable'=>'migcms_codes','lbkey'=>'id','lbdisplay'=>'id_textid_name','lbwhere'=>"id_code_type='5'",'lbordby'=>"ordby",'fieldvalues'=>'','hidden'=>0},
	

);


#     },
%dm_display_fields = (
    	"1/$migctrad{adm_lastname}"=>"lastname",

	"2/$migctrad{adm_firstname}"=>"firstname",
	"3/Clé API"=>"api_key",
		# "3/Fonction"=>"id_textid_fonction",

	# "4/Acheteur"=>"acheteur",
	# "5/Vendeur"=>"vendeur",
	# "6/Langue(s)"=>"langues",
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


sub after_save
{
    my $dbh=$_[0];
    my $id=$_[1];

    #create token for all members
    my @members = sql_lines({dbh=>$dbh, table=>"users", where=>"token = '' OR api_key = ''"});
    foreach $member (@members)
    {
        my %member = %{$member};
        if($member{token} eq "")
        {
            my $new_token = create_token(50);
            my $stmt = <<"SQL";
				UPDATE users
					SET token = '$new_token'
					WHERE id = '$member{id}' and token = ''
SQL
            execstmt($dbh, $stmt);
        }
        if($member{api_key} eq "")
        {
            my $new_token = create_token(50);
            my $stmt = <<"SQL";
				UPDATE users
					SET api_key = '$new_token'
					WHERE id = '$member{id}' and api_key = ''
SQL
            execstmt($dbh, $stmt);
        }
    }
}
