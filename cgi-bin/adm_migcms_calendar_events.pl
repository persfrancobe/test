#!/usr/bin/perl -I../lib -w

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;

my $id=get_quoted('id');
$sw = $cgi->param('sw') || "list";
my $sel = get_quoted('sel');
$dm_cfg{after_add_ref}     = \&after_save;
$dm_cfg{after_mod_ref}     = \&after_save;
$dm_cfg{table_name} = "migcms_calendar_events";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_$dm_cfg{table_name}.pl?";
$dm_cfg{file_prefixe} = 'CAL';
$dm_cfg{default_ordby} = 'date_event_begin desc';

$cpt = 9;
	

%dm_dfl = (
	sprintf("%05d", $cpt++).'/date_event_begin' => {'title'=>"Date de début",'fieldtype'=>'text',data_type=>'date',search=>'n',default_value=>"$today",'mandatory'=>{"type" => 'not_empty'}},
	sprintf("%05d", $cpt++).'/time_event_begin' => {'title'=>"Heure de début",'fieldtype'=>'text',data_type=>'time',search=>'n',default_value=>"",'mandatory'=>{"type" => 'not_empty'}},
	sprintf("%05d", $cpt++).'/date_event_end' => {'title'=>"Date de fin",'fieldtype'=>'text',data_type=>'date',search=>'n',default_value=>"$today",'mandatory'=>{"type" => 'not_empty'}},
	sprintf("%05d", $cpt++).'/time_event_end' => {'title'=>"Heure de fin",'fieldtype'=>'text',data_type=>'time',search=>'n',default_value=>"",'mandatory'=>{"type" => 'not_empty'}},
	sprintf("%05d", $cpt++).'/description' => {'title'=>"Description",'fieldtype'=>'textarea',data_type=>'',search=>'y',default_value=>"",'mandatory'=>{"type" => 'not_empty'}},
	sprintf("%05d", $cpt++).'/adresse' => {'title'=>"Adresse",'fieldtype'=>'textarea',data_type=>'',search=>'y',default_value=>"",'mandatory'=>{"type" => ''}},
	sprintf("%05d", $cpt++).'/infos_contact' => {'title'=>"Infos contact",'fieldtype'=>'textarea',data_type=>'',search=>'y',default_value=>"",'mandatory'=>{"type" => ''}},
	);
	

%dm_display_fields = 
(
	sprintf("%05d", $cpt++)."/Date de début"=>"date_event_begin",
	sprintf("%05d", $cpt++)."/Heure de début"=>"time_event_begin",
	sprintf("%05d", $cpt++)."/Date de fin"=>"date_event_end",
	sprintf("%05d", $cpt++)."/Heure de fin"=>"time_event_end",
	sprintf("%05d", $cpt++)."/Description"=>"description",
);



see();

my @fcts = qw(
			list
		);

if (is_in(@fcts,$sw)) 
{ 
    dm_init();
    &$sw();

    $migc_output{content} .= $dm_output{content};
    $migc_output{title} = $dm_output{title}.$migc_output{title};
		
    print migc_app_layout($js.$migc_output{content},$migc_output{title},"",$gen_bar,$spec_bar);
}


sub after_save
{
    my $dbh=$_[0];
    my $id=$_[1];
}
