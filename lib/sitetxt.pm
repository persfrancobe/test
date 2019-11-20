#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Package de la librairie
package sitetxt;
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
@ISA = qw(Exporter);	#Permet l'export
@EXPORT = qw(
               %sitetxt
               get_sitetxt
			   sitetxt

            );
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
use def;
use tools;

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#see();
%sitetxt = ();
#see();

if(!($config{current_language} > 0))
{
	if(get_quoted('lg')>0)
	{
		$config{current_language} = get_quoted('lg');

	}
	else
	{
		$config{current_language} = 1;
	}
}

%sitetxt = %{get_sitetxt($dbh,$config{current_language})};

sub get_sitetxt
{
	my $dbh = $_[0];
	my $lg = $_[1];
 
	my %trad = ();
	
	my @tables = ('eshop_txts','members_txts','sitetxt','sitetxt_common');
	$lg =~ s/\D//g;
	
	if(!($lg > 0 && $lg <= 10))
	{
		$lg = 1;
	}
	
	foreach my $table (@tables)
	{
		my @records = sql_lines({table=>$table,select=>"keyword,lg1 as default_trad, lg$lg as trad, lg2 as alt_lg2"});
		foreach my $record (@records)
		{
			my %record = %{$record};
			
			if($trad{$record{keyword}} eq '')
			{
				$trad{$record{keyword}} = $record{trad};
				if($trad{$record{keyword}} eq '')
				{
					$trad{$record{keyword}} = $record{default_trad};
					# $trad{$record{keyword}} = "NO TRAD [$lg] FOR [$record{keyword}]";
				}
				if($table eq 'members_txts' && $config{'members_force_lg_for_lg'.$lg} > 0)
				{
					$trad{$record{keyword}} = $record{'alt_lg'.$config{'members_force_lg_for_lg'.$lg}};
				}
			}
		}
	}
	
	return (\%trad);
}

sub sitetxt
{
	my $keyword = $_[0];
	my $lg = $_[1];
	if($lg >0 && $lg < 10)
	{
	}
	else
	{
		$lg = 1;
	}
	if($sitetxt{$keyword} ne '')
	{
		return $sitetxt{$keyword};
	}
	else
	{
		my %record = sql_line({table=>'sitetxt',select=>"keyword,lg1 as default_trad, lg$lg as trad",where=>"keyword='$keyword'"});
		if($record{trad} ne '')
		{
			return $record{trad};
		}
		elsif($record{default_trad} ne '')
		{
			return $record{default_trad};
		}
	}
 }



1;