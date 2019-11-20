#!/usr/bin/perl -I../lib

use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;








$dm_cfg{customtitle} = $fwtrad{users_title};
$dm_cfg{enable_search} = 1;
$dm_cfg{deplie_recherche} = 1;
$dm_cfg{enable_multipage} = 1;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "migcms_parag_pics";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{get_form_ref} = \&get_form;
$dm_cfg{get_and_check_ref} = \&get_and_check;
$dm_cfg{table_width} = 600;
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_parag_pics_upload.pl?";
$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{after_add_ref} = \&after_save;







@dm_nav =
(
	 {
        'tab'=>'client',
		'type'=>'tab',
        'title'=>'Client'
    }
    ,
	{
        'tab'=>'avenants',
		'type'=>'tab',
        'title'=>'Avenants'
    }
    ,
	 {
        'type'=>'func',
        'func'=>'tab_fichiers',
        'title'=>'Fichiers',
		'tab'=>'fichiers',
		'disable_add'=>1,
    }
  
);
$dm_cfg{default_tab} = 'client';



$sw = $cgi->param('sw') || "adm_migcms_parag_pics_upload";

see();


my @fcts = qw(
adm_migcms_parag_pics_upload
);


if (is_in(@fcts,$sw)) { 
    dm_init();
    &$sw();
    $gen_bar = get_gen_buttonbar();
    $spec_bar = get_spec_buttonbar($sw);
    print wfw_app_layout($dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}




sub adm_migcms_parag_pics_upload
{
	see();
	my $new_token = create_token(25);
	my $size_thumb = get_quoted('size_thumb');
	my $full = dm::migcms_upload('photo',200,75,$size_thumb,'',1920,$new_token);
	
	my $id_parag = get_quoted('id_parag');
	my $table = 'migcms_parag_pics';
	my $col_parent = 'id_parag';
	my $id_block = get_quoted('id_block');
	if($id_block > 0)
	{
		$table = 'migcms_blocks_pics';
		$col_parent = 'id_block';
		$id_parag = $id_block;
	}
	
	my %last_ordby = sql_line({select=>"ordby",table=>$table,where=>"$col_parent='$id_parag'",ordby=>"ordby desc"});
	my $next_ordby = 1;
	if($last_ordby{ordby}>0)
	{
		$next_ordby += $last_ordby{ordby};
	}
	$full =~ s/\\\'/\'/g;
	
	my @splitted = split(/\./,$full);
	my $ext = pop @splitted;	
	my $url_pic_ogg = join(".",@splitted)."_ogg.".$ext;	
	my $url_pic_mini = join(".",@splitted)."_mini.".$ext;
	my $url_pic_small = join(".",@splitted)."_small.".$ext;
	my $url_pic_medium = join(".",@splitted)."_medium.".$ext;
	my $url_pic_large = join(".",@splitted)."_large.".$ext;
	
	my %migcms_parag_pic = 
	(
		$col_parent => $id_parag,
		ordby => $next_ordby,
		pic_name_orig => $full,
		token => $new_token,
		url_pic_ogg => $url_pic_ogg,
		url_pic_mini => $url_pic_mini,
		url_pic_small => $url_pic_small,
		url_pic_medium => $url_pic_medium,
		url_pic_large => $url_pic_large,
		url_pic_big => $full,
		pic_thumb_create => get_quoted('create_thumb'),
		pic_thumb_size => get_quoted('size_thumb'),
		bibliotheque => get_quoted('bibliotheque')
	);
	inserth_db($dbh,$table,\%migcms_parag_pic);
	
	exit;
}