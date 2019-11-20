package dm_publish_pdf;
@ISA = qw(Exporter);
@EXPORT = qw(
ajax_publish_pdf
do_publish_pdf
write_pdf_from_url
migcms_merge_pdf
migcms_merge_pdf2
);

use def;
use tools;
use JSON::XS;
use Digest::SHA1  qw(sha1 sha1_hex sha1_base64);
$dbh_data=$dbh;
if($dm_cfg{dbh} eq 'dbh2')
{
    $dbh_data = $dbh2;
}

sub ajax_publish_pdf
{
	# log_debug('ajax_publish_pdf','','ajax_publish_pdf');
	# ajax_publish_pdf($id,$dm_cfg{file_prefixe},$dm_cfg{table_name},$dm_cfg{self});

	my $id = get_quoted('id') || $_[0];
	my $file_prefixe = get_quoted('file_prefixe') || $_[1];
	my $table = get_quoted('table') || $_[2];
	my $script = get_quoted('script') || get_quoted('sctipt') || $_[3];
	
	# log_debug('$dm_cfg{skip_auto_publishing}:'.$dm_cfg{skip_auto_publishing},'','ajax_publish_pdf');
	# log_debug('$table:'.$table,'','ajax_publish_pdf');
	# if($dm_cfg{skip_auto_publishing} == 1)
	if($table eq 'handmade_selion_cmr')
	{
		print '';
		return '';
	} 
	
	# log_debug("id:$id table:$table script:$script","","table");
	
	my $url = do_publish_pdf($id,$table,$script,$file_prefixe);
	# log_debug('$url:'.$url,'','ajax_publish_pdf');
	if($_[0] > 0)
	{
		return '../usr/documents/'.$url;
	}
	else
	{
		print '../usr/documents/'.$url;
		exit;
	}
}

sub do_publish_pdf
{
	my $id = $_[0];
	my $table = $_[1];
	my $script_cible = $_[2];
	my $file_prefixe_rec = $_[3];
	
	# use File::Path qw(remove_tree rmtree);
	# remove_tree( '../cache/site/data', {keep_root => 1} );

	
	my $table_rec = $dm_cfg{table_name};
	if($table_rec eq '')
	{
		$table_rec = $table;
	}
	
	my $script_cible_rec = $ENV{HTTP_REFERER};
	if($script_cible_rec eq '')
	{
		$script_cible_rec = $script_cible;
	}
	my $file_prefixe = $dm_cfg{file_prefixe};
	if($file_prefixe eq '')
	{
		$file_prefixe = $file_prefixe_rec;
	}


	
	# log_debug('table:'.$table_rec,'','table');
	# log_debug('script:'.$script_cible_rec,'','table');
	
	#si le pdf existe deja dans la colonne migcms_last_published_file, renvoyer celui la !
	my %check_pdf = sql_line({debug=>0,debug_results=>0,select=>'id,migcms_last_published_file',table=>$table_rec,where=>"id='$id'"});
	
	my $existing_filename = $check_pdf{migcms_last_published_file};
	$existing_filename =~ s/\.pdf//g;
	
	
	if($check_pdf{migcms_last_published_file} ne '' && -e '../usr/documents/'.$existing_filename.'.pdf')
	{
		return $check_pdf{migcms_last_published_file}.'.pdf';
	}
	else
	{
		# my $prefixe = $dm_cfg{file_prefixe};
		
		my %sys = %{get_migcms_sys({par=>'test',nom_table=>$table_rec,id_table=>$id})};
		
		my $filename = get_document_filename({date=>1,sys=>\%sys,prefixe=>$file_prefixe,id=>$id,type=>'document'});
		# log_debug('filename'.$filename);
		
		my $url = $script_cible_rec.'&sw=get_publish_pdf_html&id='.$id.'&file_prefixe='.$file_prefixe;
		# log_debug('url:'.$url,'','table');
		# use Data::Dumper;
		# log_debug(Dumper(\%ENV),'','ENV');
		if($script_cible_rec eq '')
		{
			$url = 'http://';
			if($ENV{HTTP} eq 'on' || $ENV{REQUEST_SCHEME} eq 'https')
			{
				$url = 'https://';
			}
			$url .= $ENV{HTTP_HOST}.$ENV{SCRIPT_NAME}.'?&sw=get_publish_pdf_html&id='.$id;
			log_debug('url2:'.$url,'','table');
		}

		# my $path_new = $config{directory_path}.'/usr/documents/'.$filename.'.pdf';
		
		my $path_temp = $config{directory_path}.'/usr/documents/'.$filename.'_temp.pdf';
		my $path_new = $config{directory_path}.'/usr/documents/'.$filename.'.pdf';
		
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
		$year+=1900;	
		$mon++;	
		$url.= '&timever='.$hour.$min.$sec; 
		write_pdf_from_url($path_temp,$url);
		
		
		migcms_merge_pdf($path_temp,$path_new,$table_rec,$id);
		
		$stmt = "update $table_rec SET migcms_last_published_file = '$filename' WHERE id = '".$id ."' ";

		execstmt($dbh,$stmt);
		# log_debug($stmt,'','table');
		

		return $filename.'.pdf';
	}
}

sub write_pdf_from_url
{
	my $pdf = $_[0];
	my $url = $_[1];
	
	my $wkpath = '/usr/local/wkhtmltox/bin/wkhtmltopdf';
	if($config{wkpath} ne '')
	{
		$wkpath = $config{wkpath};
	}
	log_debug("$wkpath --lowquality --print-media-type --no-header-line --no-footer-line '$url' $pdf;","","wk");
	log_debug($url,"","wk");

	`$wkpath --lowquality --print-media-type --no-header-line --no-footer-line '$url' $pdf`;
	
	log_debug('write_pdf_from_url OK',"","wk");
}



sub migcms_merge_pdf
{
	
	# log_debug('ENTRE DANS migcms_merge_pdf','','cree_pdf');

	my $path_temp = $_[0];
	my $path_new = $_[1];
	my $table = $_[2];
	my $id = $_[3];
	my $no_temp_doc = $_[4];
	my $col = $_[5];
	
	# log_debug('','vide','debug_migcms_merge_pdf');
	# log_debug('migcms_merge_pdf','','debug_migcms_merge_pdf');
	# log_debug('$path_temp:'.$path_temp,'','debug_migcms_merge_pdf');
	# log_debug('$path_new:'.$path_new,'','debug_migcms_merge_pdf');
	# log_debug('$table:'.$table,'','debug_migcms_merge_pdf');
	# log_debug('$id:'.$id,'','debug_migcms_merge_pdf');
	# log_debug('$no_temp_doc:'.$no_temp_doc,'','debug_migcms_merge_pdf');
# log_debug('PARAMS ok','','cree_pdf');
	use PDF::API2;
	
	# log_debug('API ok','','cree_pdf');
	my $big_pdf = PDF::API2->new(-file => $path_new);
	# log_debug('$big_pdf:'.$big_pdf,'','debug_migcms_merge_pdf');

	my $pds;
	if($no_temp_doc ne 'no_temp_doc')
	{
		eval { $pds = PDF::API2->open( $path_temp ) };
			log_debug('eval ok:'.$path_temp,'','debug_migcms_merge_pdf');

	# use Carp;	
	# my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller();
	# my $stack = Carp::longmess("Stack backtrace :");
	# $stack =~ s/\r*\n/<br>/g;	
	# print $stack;
		log_debug('avant pages','','debug_migcms_merge_pdf');
		my $pn = $pds->pages;
		$big_pdf->importpage($pds,$_) for 1..$pn-1;
		log_debug('apres pages','','debug_migcms_merge_pdf');
		# unlink($path_temp);
	}
	
	my $where_lf = "table_name='$table' AND token='$id'";
	if($col ne "")
	{
		$where_lf .= " AND table_field='$col' ";
	}
	
	my @migcms_linked_files = sql_lines({debug=>1,debug_results=>1,table=>'migcms_linked_files',where=>$where_lf,ordby=>'ordby'});
	# log_debug('Nb fichiers lies:('.$where_lf.')'.$#migcms_linked_files,'','debug_migcms_merge_pdf');

	foreach $migcms_linked_file (@migcms_linked_files)
	{
		my %migcms_linked_file = %{$migcms_linked_file};
		$migcms_linked_file{file_dir} =~ s/^.//;
		$migcms_linked_file{file_dir} =~ s/^.//;
		
		my $file_path = $config{directory_path}.$migcms_linked_file{file_dir}.'/'.$migcms_linked_file{full}.$migcms_linked_file{ext};
		# log_debug($file_path,'','link_pdf');
		# log_debug($migcms_linked_file{ext},'','link_pdf');
		if(-e $file_path)
		{
			# log_debug('EXISTE','','link_pdf');
		}
		else
		{
			# log_debug('EXISTE PAS','','link_pdf');
		}
		
		if ($migcms_linked_file{ext} eq '.pdf')
		{
			my $pds;
			# log_debug('opening','','link_pdf');
			eval { $pds = PDF::API2->open($file_path ) };
			# log_debug('opeed','','link_pdf');
			# log_debug($@,'','link_pdf');
			if ($@) {      next;    }
			my $pn = $pds->pages;
			# log_debug('$pn:'.$pn,'','link_pdf');
			
			$big_pdf->importpage($pds,$_) for 1..$pn;
		}
	}

	$big_pdf->saveas;
	$big_pdf->end;
}
sub migcms_merge_pdf2
{
	
	# log_debug('ENTRE DANS migcms_merge_pdf2','','cree_pdf');

	my $path_temp = $_[0];
	my $path_new = $_[1];
	my $table = $_[2];
	my $id = $_[3];
	my $no_temp_doc = $_[4];
	my $col = $_[5];
	
	# log_debug('','vide','debug_migcms_merge_pdf2');
	# log_debug('migcms_merge_pdf2','','debug_migcms_merge_pdf2');
	# log_debug('$path_temp:'.$path_temp,'','debug_migcms_merge_pdf2');
	# log_debug('$path_new:'.$path_new,'','debug_migcms_merge_pdf2');
	# log_debug('$table:'.$table,'','debug_migcms_merge_pdf2');
	# log_debug('$id:'.$id,'','debug_migcms_merge_pdf2');
	# log_debug('$no_temp_doc:'.$no_temp_doc,'','debug_migcms_merge_pdf2');
        # log_debug('PARAMS ok','','cree_pdf');
	use PDF::API2;
	
	# log_debug('API ok','','cree_pdf');
	# log_debug('$big_pdf:'.$big_pdf,'','debug_migcms_merge_pdf2');

	my @pds;
	
	my $where_lf = "table_name='$table' AND token='$id'";
	if($col ne "")
	{
		$where_lf .= " AND table_field='$col' ";
	}
	
	my @migcms_linked_files = sql_lines({debug=>1,debug_results=>1,table=>'migcms_linked_files',where=>$where_lf,ordby=>'ordby'});
	log_debug('Nb fichiers lies:('.$where_lf.')'.$#migcms_linked_files,'','debug_migcms_merge_pdf2');

	foreach $migcms_linked_file (@migcms_linked_files)
	{
		my %migcms_linked_file = %{$migcms_linked_file};
		$migcms_linked_file{file_dir} =~ s/^.//;
		$migcms_linked_file{file_dir} =~ s/^.//;
		
		my $file_path = $config{directory_path}.$migcms_linked_file{file_dir}.'/'.$migcms_linked_file{full}.$migcms_linked_file{ext};
		# log_debug($file_path,'','debug_migcms_merge_pdf2');
		# log_debug($migcms_linked_file{ext},'','debug_migcms_merge_pdf2');
		if(-e $file_path)
		{
			log_debug('EXISTE','','debug_migcms_merge_pdf2');
		}
		else
		{
			log_debug('EXISTE PAS','','debug_migcms_merge_pdf2');
		}
		
		if ($migcms_linked_file{ext} eq '.pdf')
		{
                        push @pds,$file_path;
		}
	}
 
	# log_debug('debut crop ','','debug_migcms_merge_pdf2');
	# my $path_cropped = $path_new;
	# $path_cropped =~ s/\.pdf/\_cropped\.pdf/g;
	
	# my $cropped_pdf = PDF::API2->new(-file => $path_cropped);
	# eval { $pds = PDF::API2->open( $path_temp ) };
	# my $pn = $pds->pages;
	# $cropped_pdf ->importpage($pds,$_) for 1..$pn-1;
	# $cropped_pdf->saveas;
	# $cropped_pdf->end;


 
       # my $merge_pdf_cmd = "mutool merge -o $path_new $path_cropped ".join(' ',@pds);
       
	   
	   my $merge_pdf_cmd = "mutool merge -o $path_new $path_temp ".join(' ',@pds);
	   	   	log_debug($table,'','debug_migcms_merge_pdf2');

			
		# if(!(-e $path_new))
		# {
			# $path_new = "";
		# }
		# if(!(-e $path_temp))
		# {
			# $path_temp = "";
		# }
		
			
	   if($table eq 'handmade_selion_cmr')
	   {
			$merge_pdf_cmd = "mutool merge -o $path_new $path_temp  ".join(' ',@pds); 
	   }
	   
	   	# log_debug($merge_pdf_cmd,'','debug_migcms_merge_pdf2');

       system($merge_pdf_cmd);

}

1;