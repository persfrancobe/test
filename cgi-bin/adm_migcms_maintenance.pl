#!/usr/bin/perl -I../lib 
#                  -d:NYTProf
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use Crypt::OpenSSL::RSA;
use migcrender;
use Data::Dumper;
use sitetxt;
use JSON::XS;
use members;


my $sw = get_quoted('sw') || "clean_textcontents";


my $self = "cgi-bin/adm_migcms_maintenance.pl?&";
my @fcts = qw(
clean_textcontents
);


&$sw();


sub clean_textcontents
{
	see();
	my @list_of_tables = get_list_of_tables($config{projectname});
	
	my @eligible_textcontents = ();
	my $delete = get_quoted('delete') || 'y';
	$delete='y';
	
	my $i = 0;
	
	foreach my $table (@list_of_tables)
    {    
        print "<br><b>$table ($i)</b>";
		if($table eq 'txtcontents' || $table eq 'textcontents')
		{
			next;
		}
		my @list_of_cols = get_list_of_cols($config{projectname},$table);   
               
        foreach my $col (@list_of_cols)
        {
            my %col = %{$col};
			my $colname = $col{COLUMN_NAME};
			
			if($colname  =~ /textid/ )
			{
				print "<br><i style='color:green'>$colname</i>";
				my @textcontents_to_add = sql_lines({debug=>0,debug_results=>0, table=>$table,select=>"$colname as id_trad"});
				foreach $textcontent_to_add (@textcontents_to_add)
				{
					my %textcontent_to_add = %{$textcontent_to_add};
					if($textcontent_to_add{id_trad} > 0)
					{
						push @eligible_textcontents, $textcontent_to_add{id_trad};
						$i++;
						print " ".$textcontent_to_add{id_trad};
						# print ' ajout de '.$textcontent_to_add{id_trad};
					}
				}
			}
			else
			{
				# print "<br><span style='color:#dddddd'>$colname</span>";
			}
        }  

		if(1 && $table eq 'data_sheets')
		{
			my @data_sheets = sql_lines({table=>$table,select=>'*'});
			foreach $data_sheet (@data_sheets)
			{
				my %data_sheet = %{$data_sheet};
				foreach $numcol (1 .. 70)
				{
					if($data_sheet{'f'.$numcol}>0 && $data_sheet{'f'.$numcol} =~ /^\d*$/)
					{
						push @eligible_textcontents, $data_sheet{'f'.$numcol};
						$i++;
						# print " ".$data_sheet{'f'.$numcol};

						# print '<span style="color:green">['.$data_sheet{'f'.$numcol}.']</span>';
					}
					else
					{
						# print '<span style="color:red">['.$data_sheet{'f'.$numcol}.']</span>';
					}
				}
			}
		}
    }
	
	print '<hr><h1>'.$i.' textes seront conservés</h1>';
	# exit;
	# print Dumper \@eligible_textcontents;
	
	
	
	my @textcontents = sql_lines({table=>'txtcontents'});
	foreach $textcontent (@textcontents)
	{
		my %textcontent = %{$textcontent};
		
		my $a_supprimer = 1;
		
		foreach my $eligible_textcontent (@eligible_textcontents)
		{
			if($eligible_textcontent == $textcontent{id})
			{
				$a_supprimer = 0;
			}
		}
		
		if($delete eq 'y')
		{
		
			if($a_supprimer == 1)
			{
				my $stmt="DELETE FROM txtcontents WHERE id = $textcontent{id}";
				print "<br />[$stmt]";
				execstmt($dbh,$stmt);		
			}
		
		}
		else
		{
			print '<br>sera supp: '.$textcontent{id};
		}
	}
	
	print '<hr>';
	exit;
}

sub get_list_of_cols()
{
    #list of COLS
    my @list_of_cols =();
    my $stmt_list_of_cols = "SELECT COLUMN_NAME, DATA_TYPE, COLUMN_DEFAULT FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA ='$_[0]' AND table_name = '$_[1]'";
    my $cursor_list_of_cols = $dbh->prepare($stmt_list_of_cols) || die("CANNOT PREPARE $stmt_list_of_cols");
    $cursor_list_of_cols->execute || suicide($stmt_list_of_cols);
    while ($ref_rec = $cursor_list_of_cols->fetchrow_hashref()) 
    {
        push @list_of_cols,\%{$ref_rec};
    }
    $cursor_list_of_cols->finish;
    return @list_of_cols;
}

sub get_list_of_tables()
{
    #list of TABLES
    my @list_of_tables =();
    my $stmt_list_of_tables = "SELECT t.TABLE_NAME AS stud_tables FROM INFORMATION_SCHEMA.TABLES AS t WHERE t.TABLE_TYPE = 'BASE TABLE' AND t.TABLE_SCHEMA = '$_[0]'";
    my $cursor_list_of_tables = $dbh->prepare($stmt_list_of_tables) || die("CANNOT PREPARE $stmt_list_of_tables");
    $cursor_list_of_tables->execute || suicide($stmt_list_of_tables);
    while ($ref_rec = $cursor_list_of_tables->fetchrow_hashref()) 
  	{
        push @list_of_tables,$ref_rec->{stud_tables};
  	}
  	$cursor_list_of_tables->finish;
    return @list_of_tables;
}