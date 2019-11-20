#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use def_handmade;
use tools; # home-made package for tools
use dm;
use sitetxt;

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###############################################################################################
####################################	CODE DU PROGRAMME		######################################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


$sw = 'migcms_simple_upload_file';

see();

my @fcts = qw(
			migcms_simple_upload_file
		);

if (is_in(@fcts,$sw)) 
{ 
    &$sw();
	exit;
}


sub migcms_simple_upload_file
{
   	use GD;	
	GD::Image->trueColor(1);	
	log_debug('migcms_simple_upload_file','vide','migcms_simple_upload_file');
                               
	if ($handmade_cfg{custom_simple_upload_file} ne "") 
	{
		log_debug('->'.$handmade_cfg{custom_simple_upload_file},'','migcms_simple_upload_file');
		my $func = $handmade_cfg{custom_simple_upload_file};
		return &$func();      
	}

	see();
	my $pic = $cgi->param('file');
	my $file_prefixe = $ENV{HTTP_FILE_PREFIXE};
	my $table_name = $ENV{HTTP_TABLE_NAME};
	my $token = $ENV{HTTP_TOKEN};

	my $pic_dir = '';
	my $force_file_url = '';
	my $id_pic = 0;
	my ($ext) = $pic =~ /(\.[^.]+)$/;
	my ($full,$fullname,$orig_size);
	my @sizes = ('mini','small','medium','large','og');
	
	#CREATE DIR ---------------------------------------------------------------------------------------
	my ($file_prefixe,$token,$table_name,$filename,$min_width) = split(/\-/,$ENV{QUERY_STRING});
	my $suffix = '';
	
	my $do_create_thumbs = get_quoted('do_create_thumbs') || 'n';
	my $delete_previous_pic = get_quoted('delete_previous_pic') || 'n';
	if($config{'delete_previous_pic_'.$table_name} eq 'y')
	{
		$delete_previous_pic = $config{'delete_previous_pic_'.$table_name};
	}
	
	
	my $ordby_force = get_quoted('ordby_force');
	
	if(get_quoted('filename') ne '')
	{
		$filename = get_quoted('filename');
	}
	if(get_quoted('file_prefixe') ne '')
	{
		$file_prefixe = get_quoted('file_prefixe');
	}
	if(get_quoted('table_name') ne '')
	{
		$table_name = get_quoted('table_name');
	}
	if(get_quoted('token') ne '')
	{
		$token = get_quoted('token');
	}
	
	if(1 && $delete_previous_pic eq 'y')
	{
		my %last_migcms_linked_file = sql_line({debug=>0,debug_results=>0,select=>"id",table=>'migcms_linked_files',where=>"table_field='$filename' AND table_name='$table_name' AND token='$token' AND ordby_force='$ordby_force'"});
		
		log_debug('DELETE PREVIOUS PIC '.$last_migcms_linked_file{id},'','migcms_simple_upload_file');
		if($last_migcms_linked_file{id} > 0)
		{
			migcms_simple_upload_file_list_del_file($last_migcms_linked_file{id});
		}
	}
	
	log_debug('filename:'.$filename,'','migcms_simple_upload_file');
	log_debug('file_prefixe:'.$file_prefixe,'','migcms_simple_upload_file');
	log_debug('table_name:'.$table_name,'','migcms_simple_upload_file');
	log_debug('token:'.$token,'','migcms_simple_upload_file');

	
	if($file_prefixe ne '' && $token > 0)
	{
		$suffix = '/'.$file_prefixe.'/'.$filename.'/'.$token;
	}
	my $dir = $config{directory_path}.'/usr/files/'.$file_prefixe;
	unless (-d $dir) {mkdir($dir.'/') or die ("cannot create ".$dir.": $!");}
	my $dir = $config{directory_path}.'/usr/files/'.$file_prefixe.'/'.$filename;
	unless (-d $dir) {mkdir($dir.'/') or die ("cannot create ".$dir.": $!");}
	my $dir = $config{directory_path}.'/usr/files/'.$file_prefixe.'/'.$filename.'/'.$token;
	unless (-d $dir) {mkdir($dir.'/') or die ("cannot create ".$dir.": $!");}
	$pic_dir = '../usr/files'.$suffix ;
	unless (-d $config{directory_path}.'/usr/files'.$suffix) {mkdir($config{directory_path}.'/usr/files'.$suffix.'/') or die ("cannot create "."$config{directory_path}".'/usr/files'.$suffix.": $!");}

	log_debug('dossiers ok: '.$config{directory_path}.'/usr/files'.$suffix,'','migcms_simple_upload_file');

	
	my $next_num = 1;
	
	#UPLOAD ORIGINAL------------------------------------------------------------------------------
	
	#renome si on est pas dans le CMS
	if($config{keep_original_name} ne 'y' && $table_name ne 'migcms_blocks' && $table_name ne 'parag' && $table_name ne 'migcms_pages' && $table_name ne 'migcms_file_manager' && $table_name ne 'data_sheets')
	{
		my @files_array = ();
		
		my %sys = ();
		if($config{use_sys} eq 'y')
		{
			%sys = sql_line({table=>'migcms_sys',where=>"nom_table='$table_name' AND id_table='$token'"});
		}
		
		my %last_migcms_linked_file = sql_line({debug=>0,debug_results=>0,select=>"MAX(ordby) as max_ordby",table=>'migcms_linked_files',where=>"table_field='$filename' AND table_name='$table_name' AND token='$token'"});
		if($last_migcms_linked_file{max_ordby} > 0)
		{
			$next_num = $last_migcms_linked_file{max_ordby} + 1;
		}
		else
		{
			$next_num = 1;
		}
		my $next_num_f = sprintf("%03d",$next_num);
		my $document_filename = get_document_filename({sequence=>$next_num_f,date=>1,prefixe=>$file_prefixe,type=>'document',id=>$token,sys=>\%sys});		
		$force_file_url = $document_filename;
	}
	else
	{
		$force_file_url = $full;
	}
	
	log_debug('upload de '.$force_file_url.'('.$pic.')','','migcms_simple_upload_file');
	
	#upload le fichier
	($full,$fullname,$orig_size) = migcms_do_upload_file($pic,$pic_dir,'',$force_file_url);
	($ext) = $full =~ /(\.[^.]+)$/;
	 $full =~ s/(\.[^.]+)$//g;

	 $pic =~ s/\'/\\\'/g;
	 
	 my $pic_dir_test = $pic_dir;
	 $pic_dir_test =~ s/\.\.\///g;
	 $pic_dir_test = $config{directory_path}.'/'.$pic_dir_test;
	 my $pic_test = $pic_dir_test.'/'.$full.$ext;
	 
	 my $fu_width = $fu_height = 0;
	 if($ext =~ /jpg/)
	 {
		  $test_full = GD::Image->new($pic_test) || log_debug("GD cannot open $pic_test : [$!]");	
		 ($fu_width,$fu_height) = $test_full->getBounds();	
	 }
	 
	 
	 

	
	 
	 #insert linked file in database
	 my %migcms_linked_file =
	 (
		file        => $pic,
		file_dir    => $pic_dir,
		file_path   => $pic_path,
		ordby       => $next_num,
		ordby_force       => $ordby_force,
		moment      => 'NOW()',
		table_name  => $table_name,
		table_field => $filename,
		token       => $token,
		full        => $full,
		width_full        => $fu_width,
		height_full        => $fu_height,
		ext         => $ext,
		size        => $orig_size,
		visible        => 'y',
	 );
	my $id_migcms_linked_file = inserth_db($dbh,"migcms_linked_files",\%migcms_linked_file);
	log_debug($id_migcms_linked_file,'','migcms_simple_upload_file');
	log_debug($do_create_thumbs,'','migcms_simple_upload_file');
	
	#update linked file with thumbs if required
	if(1 && $do_create_thumbs eq 'y')
	{
		my %data_family = sql_line({table=>'data_families',where=>"id='2'"});
		$migcms_linked_file{id} =  $id_migcms_linked_file;
		my %params = (
			migcms_linked_file=>\%migcms_linked_file,
			do_not_resize=>'n',
		);
		foreach my $size (@sizes)
		{
			$params{'size_'.$size} = $data_family{$size.'_width'};
			log_debug('Taille '.$size.'('.$params{'size_'.$size}.')','','migcms_simple_upload_file');

		}
		log_debug('appel de migcms_simple_upload_file_resize_pic','','migcms_simple_upload_file');
		migcms_simple_upload_file_resize_pic(\%params);
		log_debug('appel de migcms_simple_upload_file_resize_pic ok','','migcms_simple_upload_file');
	}

  # On créé une légende par défaut basée sur le nom du fichier
	# récupération des langues actives
	my @languages = sql_lines({debug_results=>0,dbh=>$dbh, table=>"migcms_languages", where=>"visible = 'y' OR encode_ok = 'y'"});
	my $id_traduction;
	foreach $language (@languages)
	{
		my %language = %{$language};
		# see(\%language);

		# Pour chaque langue, on met le nom du fichier/photo
		$id_traduction = set_traduction({id_language=>$language{id},id_traduction=>$id_traduction, traduction=>$pic,table_record=>'migcms_linked_files',col_record=>'id_textid_legend',id_record=>$id_migcms_linked_file});
	}

	 # print "$min_width > 0 && $min_width > $fu_width";
	 if($min_width > 0 && $min_width > $fu_width)	 
	 {
		migcms_simple_upload_file_list_del_file($id_migcms_linked_file);
	 }
	 exit;
}

sub migcms_simple_upload_file_resize_pic
{
	my %d = %{$_[0]};
	
	log_debug("migcms_simple_upload_file_resize_pic",'','migcms_simple_upload_file_resize_pic');
	log_debug($d{do_not_resize},'','migcms_simple_upload_file_resize_pic');
	
	my %update_migcms_linked_file = ();
	my @sizes = ('mini','small','medium','large','og');
	$update_migcms_linked_file{do_not_resize} = $d{do_not_resize};
	my $full_pic = $d{migcms_linked_file}{'full'}.$d{migcms_linked_file}{'ext'};
	foreach my $size (@sizes)
	{
		log_debug($size,'','migcms_simple_upload_file_resize_pic');

		
		#supprimer le fichier miniature existante s'il existe
		if(trim($d{migcms_linked_file}{'name_'.$size}) ne '' && $d{migcms_linked_file}{'name_'.$size} ne '.' && $d{migcms_linked_file}{'name_'.$size} ne '..' && $d{migcms_linked_file}{'name_'.$size} ne '/')
		{
			my $existing_file_url = $d{migcms_linked_file}{file_dir}.'/'.$d{migcms_linked_file}{'name_'.$size};
			log_debug($existing_file_url,'','migcms_simple_upload_file_resize_pic');

			if(-e $existing_file_url)
			{
				log_debug("unlink($existing_file_url);",'','migcms_simple_upload_file_resize_pic');
				unlink($existing_file_url);
				log_debug("unlink($existing_file_url)",'','migcms_simple_upload_file_resize_pic');
			}
			else
			{
				log_debug('existe pas','','migcms_simple_upload_file_resize_pic');
			}
		}
		
		if
		(
			$d{do_not_resize} eq 'y'
		)
		{
			#ne pas redimensionner: nettoyer données existantes
			$update_migcms_linked_file{'size_'.$size} = 0;
			$update_migcms_linked_file{'width_'.$size} = 0;
			$update_migcms_linked_file{'height_'.$size} = 0;
			$update_migcms_linked_file{'name_'.$size} = '';
		}
		else
		{
			#créer une nouvelle miniature
			log_debug("size:>0?".$d{'size_'.$size},'','migcms_simple_upload_file_resize_pic');
			if($d{'size_'.$size} > 0)
			{
				log_debug('2size_'.$size.':'.$d{'size_'.$size},'','migcms_simple_upload_file_resize_pic');
				($thumb,$thumb_width,$thumb_height,$full_width,$full_height) = thumbnailize($full_pic,$d{migcms_linked_file}{file_dir},$d{'size_'.$size},$d{'size_'.$size},'_'.$size);
				$update_migcms_linked_file{'size_'.$size} = $d{'size_'.$size};
				$update_migcms_linked_file{'width_'.$size} = $thumb_width;
				$update_migcms_linked_file{'height_'.$size} = $thumb_height;
				$update_migcms_linked_file{'name_'.$size} = $thumb;
			}
		}
		updateh_db($dbh,"migcms_linked_files",\%update_migcms_linked_file,'id',$d{migcms_linked_file}{id});
	}
}

sub migcms_simple_upload_file_list_del_file
{
	see();
	my $id_migcms_linked_file = get_quoted('id_migcms_linked_file') || $_[0];
	my $edit_id = get_quoted('edit_id');
	my $file_name = get_quoted('file_name');
	my $table_name = get_quoted('table_name');
		
	my %migcms_linked_file = ();
	
	if($id_migcms_linked_file > 0)
	{
		%migcms_linked_file = read_table($dbh,'migcms_linked_files',$id_migcms_linked_file);
	}
	elsif($edit_id > 0 && $file_name ne '' && $table_name ne '')
	{
		%migcms_linked_file = sql_line({table=>'migcms_linked_files',where=>"file='$file_name' AND token='$edit_id' AND table_name ='$table_name'"});
	}
	
	


	#unlink file and thumbs
	my @cols = ('full','name_mini','name_small','name_medium','name_large','name_og');
	foreach my $col (@cols)
	{
		my $url = $migcms_linked_file{file_dir}.'/'.$migcms_linked_file{$col};
		if($col eq 'full')
		{
			$url .= $migcms_linked_file{ext};
		}

		if(-e $url)
		{
			unlink($url);
		}
		else
		{
			#cant find
		}
	}

	$stmt = "delete FROM migcms_linked_files WHERE id = '$migcms_linked_file{id}' ";
	execstmt($dbh,$stmt);
}