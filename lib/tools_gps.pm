#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
package tools_gps;
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
@ISA = qw(Exporter);	
@EXPORT = qw(
get_distance_from_adresses_or_gps
);
use tools;
use JSON::XS;
use LWP::Simple;


sub get_distance_from_adresses_or_gps
{
	log_debug('get_distance_from_adresses_or_gps','','after_save');
	my %d = %{$_[0]};
	
	$d{origin_adresse} =~ s/\s/\+/g;
	$d{destination_adresse} =~ s/\s/\+/g;
	
	my $gps_origin = '';
	if($d{origin_lat} ne '' && $d{origin_lon} ne '')
	{
		$gps_origin = $d{origin_lat}.','.$d{origin_lon};
	}
	else
	{
		$gps_origin = $d{origin_adresse};
	}
	log_debug('$gps_origin:'.$gps_origin,'','after_save');

	
	
	my $gps_destination = '';
	if($d{destination_lat} ne '' && $d{destination_lon} ne '')
	{
		$gps_destination = $d{destination_lat}.','.$d{destination_lon};
	}
	else
	{
		$gps_destination = $d{destination_adresse};
	}
	log_debug('$gps_destination:'.$gps_destination,'','after_save');
	
	
	
	my $url = 'https://maps.googleapis.com/maps/api/distancematrix/json?origins='.$gps_origin.'&destinations='.$gps_destination.'&language=fr-FR&key='.$d{key};
	log_debug($d{label}.' $url:'.$url,'','after_save');
	
	my $content = get($url);
	my $nb_km = 0;
	if($content ne '')
	{
		my $content_ref=decode_json $content;
		my %hash_res=%{$content_ref};
		$nb_km = $hash_res{rows}[0]{elements}[0]{distance}{value};
		log_debug($d{label}.' $nb_km:'.$nb_km,'','after_save');
	}
	return $nb_km;
}

1;