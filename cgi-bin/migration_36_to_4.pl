#!/usr/bin/perl -I../lib 

use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;

$cgi = new CGI;
$sw = get_quoted('sw') || "start";
my $extlink = get_quoted('extlink');
$config{current_language} = get_quoted('lg') || 1;


my $lg=get_quoted('lg') || "1";
my $self = "cgi-bin/migration_36_to_4.pl?";
&$sw();

sub start()
{      
    see();
	
	#users: compléter prénom à partir d'identity, compléter mot de passe
	my $stmt = "UPDATE users SET lastname = identity, password = passwd where lastname = ''";
	execstmt($dbh,$stmt);	
	
    # copy_txtcontents();
    # copy_pages();
	# copy_blocks();
	# copy_parag_pics();
	exit;
}

sub copy_parag_pics
{
	my @pics = sql_lines({table=>'pics',where=>"table_name='parag' AND id_table > 0 and pic_name_full != '' "});
    foreach $p (@pics)
    {
        my %p = %{$p};
       
        my %np = (
        'id_parag' => $p{id_table},
        'ordby' => $p{ordby},
        'pic_name_orig' => $p{pic_name_full},
        'pic_path_orig' => '',
        'pic_thumb_create' => $p{secure},
        'pic_thumb_size' => $p{pic_width_small},
        'id_textid_alt' => $p{id_textid_alt},
        'id_textid_url' => insert_text($dbh,$p{url},1),
        'lightbox' => $p{lightbox},
        'new_window' => $p{blank},
        'url_pic_small'=> $p{pic_name_small},
        'url_pic_big'=>$p{pic_name_full},
		'url_pic_ogg'=>'',
        );
        sql_set_data({debug=>0,dbh=>$dbh,table=>'migcms_parag_pics',data=>\%np, where=>"id_parag='$np{id_parag}' AND ordby='$np{ordby}'"});               
    }
    
    print "<br />Photos copiées";
	
	
	# my $id =$_[1];
	
    # my %pic = sql_line({debug=>0,debug_results=>0,table=>'migcms_parag_pics',where=>"id=$id"});
	
    # my $orig = $config{directory_path}.'/'.$pic{pic_path_orig}.'/'.$pic{pic_name_orig};
    

    # if(-e $orig)
    # {
			# ($orig_width, $orig_height ) = imgsize($orig);
			# my $orig_path = $config{directory_path}.'/'.$pic{pic_path_orig};
            # ($small,$small_width,$small_height,$orig_width,$orig_height) = thumbnailize($pic{pic_name_orig},$orig_path,$pic{pic_thumb_size},$pic{pic_thumb_size},"_small",$config{pic_dir});
            # ($full,$full_width,$full_height,$orig_width,$orig_height) = thumbnailize($pic{pic_name_orig},$orig_path,1200,1200,"_full",$config{pic_dir});
            # ($og,$og_width,$og_height,$orig_width,$orig_height) = thumbnailize($pic{pic_name_orig},$orig_path,130,130,"_og",$config{pic_dir});
            # my %pic_update =
            # (
                # url_pic_small => "$small",
                # url_pic_big => "$full",
                # url_pic_ogg => "$og",               
            # );
            # updateh_db($dbh,'migcms_parag_pics',\%pic_update,"id",$pic{id});


}


sub copy_blocks
{
    my %txtcontents = ();
    my @blocs = sql_lines({table=>'migc_blocks'});
    my $new_ordby = 1;
    foreach $b (@blocs)
    {
        my %b = %{$b};
		
		my $type = 'content';
		if($b{type_obj} eq 'ext')
		{
			$type = 'function';
		}
		elsif($b{type_obj} eq 'menu')
		{
			$type = 'menu';
		}
		
		my %parag = read_table($dbh,'parag',$b{id_parag});
		
		
		
		
		
			
        my %nb = (
        'type' => $type,
        'visible' => $b{visible},
        'id_template' => $parag{id_template}, #$b{id_bloctpl},
		'id_template_menu' => $b{id_template},
        'id_blocktype' => $b{blocktype},
        'id_textid_title' => $parag{id_textid_title},
        'id_textid_content' => $parag{id_textid_parag},
        'function' => $b{params},
        'id_page_directory' => $b{id_obj},
        'ordby'=> $new_ordby++,
        'id'=>$b{id},
        );
        my $id_block = sql_set_data({debug=>0,dbh=>$dbh,table=>'migcms_blocks',data=>\%nb, where=>"id='$b{id}'"});               
		
		my @pics = sql_lines({table=>'pics',where=>"table_name='parag' AND id_table = '$parag{id}' and pic_name_full != '' "});
		foreach $p (@pics)
		{
			my %p = %{$p};
		   
			my %np = (
			'id_block' => $id_block,
			'ordby' => $p{ordby},
			'pic_name_orig' => $p{pic_name_full},
			'pic_path_orig' => '',
			'pic_thumb_create' => $p{secure},
			'pic_thumb_size' => $p{pic_width_small},
			'id_textid_alt' => $p{id_textid_alt},
			'id_textid_url' => insert_text($dbh,$p{url},1),
			'lightbox' => $p{lightbox},
			'new_window' => $p{blank},
			'url_pic_small'=> $p{pic_name_small},
			'url_pic_big'=>$p{pic_name_full},
			'url_pic_ogg'=>'',
			);
			sql_set_data({debug=>0,dbh=>$dbh,table=>'migcms_blocks_pics',data=>\%np, where=>"id_block='$np{id_block}' AND ordby='$np{ordby}'"});               
		}
    }
    
    print "<br />Blocs copiés";
}

sub copy_pages
{
    my %txtcontents = ();
    my @pages = sql_lines({table=>'pages',where=>"id IN (select id_obj from tree)"});
    my $new_ordby = 1;
    foreach $p (@pages)
    {
        my %p = %{$p};
       
        my %np = (
        'migcms_pages_type' => 'page',
        'id_textid_name' => $p{id_textid_name},
        'id_tpl_page' => $p{id_template},
        'id_father' => 0,
        'secure' => $p{secure},
        'id_textid_meta_keywords' => $p{id_textid_refkeywords},
        'id_textid_meta_description' => $p{id_textid_refdescription},
        'id_textid_meta_title' => $p{id_textid_reftitle},
        'id_textid_meta_url' => $p{id_textid_refurl},
        'visible' => 'n',
        'ordby'=> $new_ordby++,
        'id'=>$p{id},
        );
        sql_set_data({debug=>0,dbh=>$dbh,table=>'migcms_pages',data=>\%np, where=>"id='$p{id}'"});               
    }
    
    print "<br />Pages copiées";
}

sub copy_txtcontents
{
    my %txtcontents = ();
    my @textcontents = sql_lines({table=>'textcontents'});
    foreach $t (@textcontents)
    {
        my %t = %{$t};
        $t{content} =~ s/\'/\\\'/g;
        $txtcontents{$t{id_textid}}{'lg'.$t{id_language}} = $t{content};
    }
    foreach $id_textid (keys %txtcontents)
    {
        my %record = %{$txtcontents{$id_textid}};
        $record{id} = $id_textid;
        sql_set_data({debug=>0,dbh=>$dbh,table=>'txtcontents',data=>\%record, where=>"id='$id_textid'"});                                  
    }
    print "<br />Txtcontents copiés";
}