#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;
use dm_cms;
use sitetxt;
use migcrender;
use members;
use data;
use Unicode::MapUTF8 qw(to_utf8 from_utf8 utf8_supported_charset);

my %migcms_setup = sql_line({debug=>0,table=>"migcms_setup",select=>'',where=>"",limit=>'0,1'});
my $htaccess_ssl = $config{rewrite_ssl};
my $htaccess_protocol_rewrite = "http";
if($htaccess_ssl eq 'y') {
  $htaccess_protocol_rewrite = "https";
}


$sw = $cgi->param('sw') || "clean_form";
my $sel = get_quoted('sel');

my $self = "$config{baseurl}/cgi-bin/adm_migcms_clean_certigreen.pl?&sel=".$sel;

if($sw eq 'clean_form' || $sw eq 'clean_db')
{
	&$sw(); 
}
exit;

sub check_session_validity
{
see();
exit;
}

sub clean_form
{

my $msg = '';
if(get_quoted('ko') == 1)
{
	$msg = '<div class="alert alert-danger" role="alert"> <strong>Attention:</strong> Vous devez encoder le bon code de sécurité </div>';	
}
elsif(get_quoted('ok') == 1)
{
	$msg = '<div class="alert alert-success" role="alert"> <strong>OK:</strong> Les tâches cochées ont été traitées </div>';	
}



my $page = <<"EOH";
<div class="wrapper">
	<div class="row">
		<div class="col-sm-12">
			<section class="panel text-center">
				<header class="panel-heading">
					Nettoyer le site.
				</header>
				$msg
				<div class="panel-body">
					<form method="post" action="$self">
					<input type="hidden" name="sw" value="clean_db" />
										<input type="hidden" name="sel" value="$sel" />

					<div class="well text-left">
					<br /><label style="color:red"><input type="checkbox" name="certi" value="y"  /> factures,nc,documents,reglements,clients  puis nettoyage automatique des <b>Traduction inutilisées</b> </a></label>
					<br /><br />
					<br /><label style="color:green"><input type="checkbox" name="useless_txtcontents" value="y"  /> Traductions inutilisées </a></label>
					<br /><br />
					Code de sécurité: <input type="text" autocomplete="off" name="pw" value="" />
										</div>

					
					<button type="submit" class="btn btn-lg btn-success"><i class="fa fa-check"></i> Confirmer</a>
					
					</form>
				</div>
			</section>
		</div>
	</div>
	<br />
</div>
EOH

	see();
	print migc_app_layout($page);
	exit;

}

sub clean_db
{
		my $code_securite = get_quoted('pw');
		if($code_securite ne 'a')
		{
			cgi_redirect($self.'&ko=1');		
		}
		else
		{
			see();
			if(get_quoted('certi') eq 'y')
			{
				clean_certi();
				clean_txtcontents();
			}
			if(get_quoted('useless_txtcontents') eq 'y')
			{
				clean_txtcontents();
			}	

			http_redirect($self.'&ok=1');			
		}
}

sub clean_certi
{
		# lnk_member_groups
	# mailing_lnk_member_groups
	# mailing_members

	my @truncates = qw(
		intranet_factures
		intranet_factures_bas
		intranet_facture_lignes
		handmade_certigreen_reglements
		members
		migcms_history
		commande_documents

		);
	
	foreach my $table (@truncates)
	{
		my $stmt = "TRUNCATE $table";
		execstmt($dbh,$stmt);

		my $stmt = "delete  FROM `migcms_linked_files` WHERE `table_name` = '$table';";
		execstmt($dbh,$stmt);
	}
}

sub clean_txtcontents
{
	# see();
	my @list_of_tables = get_list_of_tables($config{projectname});
	
	my @eligible_textcontents = ();
	my $delete='y';
	
	my $i = 0;
	
	
	foreach my $table (@list_of_tables)
    {    
        # print "<br><b>$table ($i)</b>";
		if($table eq 'textcontents')
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
				# print "<br><i style='color:green'>$colname</i>";
				my @textcontents_to_add = sql_lines({debug=>0,debug_results=>0, table=>$table,select=>"$colname as id_trad"});
				foreach $textcontent_to_add (@textcontents_to_add)
				{
					my %textcontent_to_add = %{$textcontent_to_add};
					if($textcontent_to_add{id_trad} > 0)
					{
						push @eligible_textcontents, $textcontent_to_add{id_trad};
						$i++;
						# print " ".$textcontent_to_add{id_trad};
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
	
	# print '<hr>Textes à conserver: <h1>'.$i.'</h1>';
	# exit;
	# print Dumper \@eligible_textcontents;
	
	
	my $i = 1;
	my $j = 1;
	my @txtcontents = sql_lines({table=>'txtcontents'});
	foreach $txtcontent (@txtcontents)
	{
		my %txtcontent = %{$txtcontent};
		
		my $a_supprimer = 1;
		
		foreach my $eligible_textcontent (@eligible_textcontents)
		{
			if($eligible_textcontent == $txtcontent{id})
			{
				$a_supprimer = 0;
			}
		}

		if($a_supprimer == 1)
		{
			if($delete eq 'y')
			{
				$i++;
						
				my $stmt="DELETE FROM txtcontents WHERE id = $txtcontent{id}";
				# print "<br />[$stmt]";
				execstmt($dbh,$stmt);		
			}
			else
			{
				$i++;
				# print '<br>sera supp: '.$txtcontent{id};
			}
		
		}
		$j++;
		
	}
	
	# print '<hr>';
	# print '<hr>Textes supprimés: <h1>'.$i.'/'.$j.'</h1>';
	# exit;
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

