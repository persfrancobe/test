#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;


$dm_cfg{vis_opt} = 1;
$dm_cfg{sort_opt} = 1;
$dm_cfg{excel} = 1;
$dm_cfg{wherel} = "id!='5'";
$dm_cfg{wherep} = "id!='5'";
$dm_cfg{table_name} = "handmade_certigreen_employes";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_$dm_cfg{table_name}.pl?";
$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{after_add_ref} = \&after_save;
# $dm_cfg{upload_file_size_min} = 600;
$dm_cfg{file_prefixe} = 'employes';
$dm_cfg{after_upload_ref} = \&after_upload;
$dm_cfg{autocreation} = 1;

$dm_cfg{hiddp}=<<"EOH";
EOH

my $cpt = 9;


     

%dm_dfl = 
(
	sprintf("%03d", $cpt++).'/firstname'=> 
	{
	'title'=>'Prénom',
	'fieldtype'=>'text',
	'search' => 'y',
	'mandatory'=>{"type" => ''},
	}
	,
	sprintf("%03d", $cpt++).'/lastname'=> 
	{
	'title'=>'Nom',
	'fieldtype'=>'text',
	'search' => 'y',
	'mandatory'=>{"type" => ''},
	}
	,
	sprintf("%03d", $cpt++).'/telephone'=> 
	{
	'title'=>'Téléphone',
	'fieldtype'=>'text',
	'data_type'=>'phone',
	'search' => 'y',
	'mandatory'=>{"type" => ''},
	}
	,
	sprintf("%03d", $cpt++).'/email'=> 
	{
	'title'=>'E-mail',
	'fieldtype'=>'text',
	'data_type'=>'email',
	'search' => 'y',
	'mandatory'=>{"type" => ''},
	}
	,
	sprintf("%03d", $cpt++).'/id_user'=>{'title'=>"Lier à l'accès",'translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},'tab'=>$tab,'default_value'=>'','lbtable'=>'users','lbkey'=>'id','lbdisplay'=>"CONCAT(firstname,' ',lastname)",'lbwhere'=>"id_role > 1 OR initiales != ''",'lbordby'=>"firstname,lastname",'fieldvalues'=>'','hidden'=>0},
	
);

%dm_display_fields = 
(
	sprintf("%03d", $cpt++).'/Prénom'=>"firstname",
	sprintf("%03d", $cpt++).'/Nom'=>"lastname",
	sprintf("%03d", $cpt++).'/Téléphone'=>"telephone",
	sprintf("%03d", $cpt++).'/Email'=>"email",
);

%dm_lnk_fields = 
(
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

if (is_in(@fcts,$sw)) 
{ 
    dm_init();
    &$sw();

    $migc_output{content} .= $dm_output{content};
    $migc_output{title} = $dm_output{title}.$migc_output{title};
    
    print migc_app_layout($migc_output{content},$migc_output{title},"",$gen_bar,$spec_bar);
}



sub after_save
{
    my $dbh = $_[0];
    my $id = $_[1];
	compute_denomination($id);
	
	my @handmade_certigreen_employes = sql_lines({table=>'handmade_certigreen_employes',where=>"", ordby=>"id"});
	foreach $handmade_certigreen_employe (@handmade_certigreen_employes)
	{
		my %handmade_certigreen_employe = %{$handmade_certigreen_employe};
		%handmade_certigreen_employe = %{quoteh(\%handmade_certigreen_employe)};
		
		#USER -------------------------------------------------------------------------------------------------------------
		if($handmade_certigreen_employe{email} ne '' && $handmade_certigreen_employe{id_user} == 0)
		{
			my %test_user = sql_line({table=>'users',where=>"email = '$handmade_certigreen_employe{email}'"});
			if($test_user{id} > 0)
			{
				#deja ok
			}
			else
			{
				my %new_user = 
				(
					'firstname' => $handmade_certigreen_employe{firstname},
					'lastname' => $handmade_certigreen_employe{lastname},
					'email' => $handmade_certigreen_employe{email},
					'password' => 'd969831eb8a99cff8c02e681f43289e5d3d69664', #temp
					'id_role' => '8', #editeur
					'visible' => 'y', 
					'token' => create_token(20),
				);
				my $new_id_user = inserth_db($dbh,'users',\%new_user);
				my $stmt = <<"EOH";
				UPDATE $dm_cfg{table_name} SET id_user = '$new_id_user' WHERE id = '$handmade_certigreen_employe{id}'
EOH
				execstmt($dbh,$stmt);
			}
		}
	}
}

sub compute_denomination
{
	my $id = $_[0];
	my %rec = sql_line({table=>$dm_cfg{table_name},where=>"id='$id'"});
	my $fusion = "$rec{firstname} $rec{lastname}";
	$fusion = trim($fusion);
	$fusion =~ s/\'/\\\'/g;	
	my $stmt = <<"EOH";
		UPDATE $dm_cfg{table_name} SET fusion = '$fusion' WHERE id = '$rec{id}'
EOH
	 execstmt($dbh,$stmt);
}
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
