#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;
      
$dbh_data = $dbh;
my $colg = get_quoted('colg')  || $config{current_language} || 1;
 my $mailing_id_campaign = get_quoted('mailing_id_campaign');
$dm_cfg{trad} = 0;
$dm_cfg{tree} = 0;
$dm_cfg{enable_search} = 1;
$dm_cfg{enable_multipage} = 0;
$dm_cfg{excel} =0;
$dm_cfg{visibility} = 0;
$dm_cfg{sort} = 0;
$dm_cfg{edit} = 1;
$dm_cfg{show_id} = 1;
$dm_cfg{duplicate} = 1;
$dm_cfg{custom_duplicate_func} = \&duplicate_page;

$dm_cfg{delete} = 1;
$dm_cfg{default_ordby} = 'id desc';
# $dm_cfg{corbeille} = 1;
# $dm_cfg{restauration} = 1;

$dm_cfg{wherep} = $dm_cfg{wherel}  = " migcms_pages_type = 'newsletter' ";
if($mailing_id_campaign > 0)
{
	$dm_cfg{wherep} = $dm_cfg{wherel}  .= " AND mailing_id_campaign = '$mailing_id_campaign' ";
}
$dm_cfg{table_name} = "migcms_pages";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_pages_newsletters.pl?mailing_id_campaign=$mailing_id_campaign";

$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{after_add_ref} = \&after_save;

	my $sel = get_quoted('sel');

$dm_cfg{'list_custom_action_1_func'} = \&custom_mailing_edit;
$dm_cfg{'list_custom_action_2_func'} = \&custom_mailing_preview;
$dm_cfg{'list_custom_action_3_func'} = \&custom_mailing_send;
$dm_cfg{'list_custom_action_4_func'} = \&custom_mailing_archives;
$dm_cfg{'list_custom_action_5_func'} = \&custom_mailing_statistiques;

my %rec_script_campagne = sql_line({table=>'scripts',where=>"url LIKE '%adm_migcms_mailings_campaigns.pl?%'"});
my %rec_script_nl = sql_line({table=>'scripts',where=>"url LIKE '%adm_migcms_pages_newsletters.pl?%'"});

%status = (
	'01/new'        =>"$migctrad{mailing_status_new}",
	'02/started'    =>"$migctrad{mailing_status_started}",
	'03/current'    =>"$migctrad{mailing_status_current}",
	'04/ended'   =>"$migctrad{mailing_status_ended}",
	'05/aborted'  =>"$migctrad{mailing_status_aborted}",
	'06/planned'  =>"$migctrad{mailing_status_planned}",
);

$dm_cfg{customtitle} = <<"EOH";
<a href="$config{baseurl}/cgi-bin/adm_migcms_mailings_campaigns.pl?&colg=$colg&sel=$rec_script_campagne{id}">Campagnes mailings</a>   
> 
<a href="$config{baseurl}/cgi-bin/adm_migcms_pages_newsletters.pl?mailing_id_campaign=$mailing_id_campaign&colg=$colg">
Newsletters
</a>  
EOH

$dm_cfg{list_html_top} .= <<"EOH";
<style>
	
		.list_ordby,.list_ordby_header,.dm_migedit 
		{
			display:none!important;
		}
	
	
	.list_line_level_1 td
	{
		background-color:#ffffff!important;
		font-size:12pt!important;
	}

	.list_line_level_2 td
	{
		background: #eee!important;
	}

     .list_ordby,.list_ordby_header
     {
        display:none;
     }
     </style>
    <input type="hidden" id="id_father" class="set_data" name="id_father" value="" />
    <script type="text/javascript"> 
    
    jQuery(document).ready(function() 
    { 
		
      
	});
	
    </script>
EOH


if($config{current_language} eq "")
{
   $config{current_language}=get_quoted('lg') || 1;
}



$dm_cfg{hiddp}=<<"EOH";

EOH

my $multisites = 1;
if($config{multisites} eq "y") {
	$multisites = 0;
}

my @basehref = sql_lines({debug=>'1',table=>'config',where=>"WHERE varname LIKE '%fullurl_%'",ordby=>"varname"});
%basehref = ();
my $i = 1;
foreach $basehref_foreach (@basehref)
{
	my %basehref_foreach = %{$basehref_foreach};
		
	$basehref{$i."/".$basehref_foreach{id}} = $basehref_foreach{varvalue};
	$i++;
}

my @google_analytics_account = sql_lines({debug=>'0',table=>'config',where=>"WHERE varname LIKE '%google_analytics%'"});
%googleanalytics = ();
my $j = 1;

foreach $google_analytics_account (@google_analytics_account)
{
	my %google_analytics_account = %{$google_analytics_account};	
	$googleanalytics{$j."/".$google_analytics_account{id}} = $google_analytics_account{varvalue};
	$j++;
} 

my $cpt = 50;

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (
	    
      '01/migcms_pages_type'=> 
      {
          'title'=>"Type",
          'fieldtype'=>'text',
          'default_value'=>'newsletter',
	        'mandatory'=>{"type" => 'not_empty'},				
		  
	      'hidden'=>1,
      }
	  ,
	  '02/mailing_id_campaign'=> 
      {
          'title'=>"id campagne",
          'fieldtype'=>'text',
	        'mandatory'=>{"type" => 'not_empty'},				
		  
	      'hidden'=>1,
      }
		,
	  '03/mailing_name'=> 
      {
	        'title'=>$migctrad{mailing_name},
	        'fieldtype'=>'text',
	        'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty'},			
	    }
		,
		'04/mailing_from'=> 
		{
	        'title'=>$migctrad{mailing_from},
	        'fieldtype'=>'text',
			'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty'},									
	        'hidden' => 0,
	    }
		,
		'05/mailing_from_email'=> 
		{
	        'title'=>$migctrad{mailing_from_email},
	        'fieldtype'=>'text',
	        'data_type'=>'email',
			'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty'},							
	        'hidden' => 0,
	    }
      ,
      '22/mailing_object'=> 
      {
	        'title'=>$migctrad{mailing_object},
	        'fieldtype'=>'text',
	        'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty'},				
	    }
		,
      '32/mailing_status'=> 
      {
	        'title'=>'Statut',
	        'fieldtype'=>'listbox',
	        'fieldvalues'=>\%status,
	        'default_value'=>'new',
	        'search' => 'y',
				      'hidden'=>1,

	    }
      ,
	  '50/id_tpl_page' => 
      {
           'title'=>$migctrad{template},
           'fieldtype'=>'listboxtable',
           'lbtable'=>'templates',
           'lbkey'=>'id',
           'lbdisplay'=>'name',
           'lbwhere'=>"type = 'mailing'" ,
	        'mandatory'=>{"type" => ''},		  
      }
	   ,
      '60/mailing_alt_html'=> 
      {
	        'title'=>$migctrad{mailing_canevas_html},
	        'fieldtype'=>'textarea',
	        'search' => 'n',
	        'mandatory'=>{"type" => ''},				
	    }
		,
	'61/mailing_basehref'=> 
      {
	        'title'=>$migctrad{mailing_basehref},
			'fieldtype'=>'listbox',
			'data_type'=>'',
			'search' => 'n',
			'mandatory'=>{"type" => ''},
			'tab'=>'',
			'default_value'=>'',
			'lbtable'=>'',
			'lbkey'=>'',
			'lbdisplay'=>'',
			'lbwhere'=>'',
			'fieldvalues'=>\%basehref,
			'hidden'=>$multisites			
	}
	,
	'62/mailing_googleanalytics'=> 
      {
	        'title'=>$migctrad{mailing_googleanalytics},
			'fieldtype'=>'listbox',
			'data_type'=>'',
			'search' => 'n',
			'mandatory'=>{"type" => ''},
			'tab'=>'',
			'default_value'=>'',
			'lbtable'=>'',
			'lbkey'=>'',
			'lbdisplay'=>'',
			'lbwhere'=>'',
			'fieldvalues'=>\%googleanalytics,
			'hidden'=>$multisites			
	}
	,
	'64/mailing_include_pics'=> 
	{
		'title'=>$migctrad{mailing_include_photos},
		'default_value'=>'n',
		'fieldtype'=>'checkbox',
		'disable_add'=>0,
	}
	,
	'65/mailing_headers'=> 
	{
		'title'=>$migctrad{mailing_headers},
		'default_value'=>'y',
		'fieldtype'=>'checkbox',
		'disable_add'=>0,
	}
	,
	'66/mailing_autoconnect'=> 
	{
		'title'=>$migctrad{mailing_autoconnect},
		'default_value'=>'n',
		'fieldtype'=>'checkbox',
		'disable_add'=>0,
	}
	,
	#champs cachés encodés pour que la duplication fonctionne
	sprintf("%05d", $cpt++).'/id_fathers'=>{'tab'=>'page','title'=>'id_fathers','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>1},
	sprintf("%05d", $cpt++).'/mailing_id_campaign'=>{'tab'=>'page','title'=>'mailing_id_campaign','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>1},
	sprintf("%05d", $cpt++).'/mailing_from'=>{'tab'=>'page','title'=>'mailing_from','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>1},
	sprintf("%05d", $cpt++).'/mailing_from_email'=>{'tab'=>'page','title'=>'mailing_from_email','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>1},
	sprintf("%05d", $cpt++).'/mailing_name'=>{'tab'=>'page','title'=>'mailing_name','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>1},
	sprintf("%05d", $cpt++).'/mailing_object'=>{'tab'=>'page','title'=>'mailing_object','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>1},
	sprintf("%05d", $cpt++).'/mailing_alt_html'=>{'tab'=>'page','title'=>'mailing_alt_html','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>1},
	sprintf("%05d", $cpt++).'/mailing_include_pics'=>{'tab'=>'page','title'=>'mailing_include_pics','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>1},
	sprintf("%05d", $cpt++).'/mailing_headers'=>{'tab'=>'page','title'=>'mailing_headers','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>1},
	sprintf("%05d", $cpt++).'/mailing_basehref'=>{'tab'=>'page','title'=>'mailing_basehref','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>1},
	sprintf("%05d", $cpt++).'/mailing_googleanalytics'=>{'tab'=>'page','title'=>'mailing_googleanalytics','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>1},
	sprintf("%05d", $cpt++).'/mailing_status'=>{'tab'=>'page','title'=>'mailing_status','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>1},
	sprintf("%05d", $cpt++).'/tracking_url'=>{'tab'=>'page','title'=>'tracking_url','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>1},

	sprintf("%05d", $cpt++).'/id_textid_meta_title'=>{'tab'=>'page','title'=>'id_textid_meta_title','translate'=>0,'fieldtype'=>'text_id','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>1},
	sprintf("%05d", $cpt++).'/id_textid_meta_url'=>{'tab'=>'page','title'=>'id_textid_meta_title','translate'=>0,'fieldtype'=>'text_id','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>1},
	sprintf("%05d", $cpt++).'/id_textid_meta_keywords'=>{'tab'=>'page','title'=>'id_textid_meta_keywords','translate'=>0,'fieldtype'=>'text_id','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>1},
	sprintf("%05d", $cpt++).'/id_textid_meta_description'=>{'tab'=>'page','title'=>'id_textid_meta_description','translate'=>0,'fieldtype'=>'text_id','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>1},
	sprintf("%05d", $cpt++).'/id_textid_url_words'=>{'tab'=>'page','title'=>'id_textid_url_words','translate'=>0,'fieldtype'=>'text_id','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>1},

	
	);

%dm_display_fields =  
(
	#"01/$migctrad{mailing_name}"=>"mailing_name",  
	"03/$migctrad{mailing_object}"=>"mailing_object",  
	#"03/$migctrad{mailing_from}"=>"mailing_from",  
	# "04/Statut"=>"mailing_status",  
); 

%dm_lnk_fields = (
	"01/Campagne"=>"campaign*",
	"02/Expéditeur"=>"sender*",
	"04/Envois"=>"nbr_sendings*",
);
                                                         
%dm_mapping_list = (
	"campaign" => \&get_campaign,
	"sender" => \&get_sender,
	"nbr_sendings" => \&get_nbr_sendings,
);

%dm_filters = (
      
		);


$sw = $cgi->param('sw') || "list";

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
    see();
    dm_init();
    &$sw();

    $migc_output{content} .= $dm_output{content};
    $migc_output{title} = $dm_output{title}.$migc_output{title};
    
    print migc_app_layout($migc_output{content},$migc_output{title});}

	

sub after_save
{
    my $dbh=$_[0];
    my $id =$_[1];
   
}


	





sub custom_mailing_edit
{
	my $id = $_[0];
	my $colg = $_[1];
	my %page = %{$_[2]};
		
	$link = '../cgi-bin/adm_migcms_parag.pl?type=mailing&id_page='.$page{id}.'&colg='.$colg.'&sel='.$sel;
	$phrase = "Editer (Ref#$id)";
	$edit_paragraphes = <<"EOH";
		<a href="$link" data-placement="bottom" data-original-title="$phrase" class="btn btn-info "> 
		<i class="fa fa-pencil fa-fw"></i> </a>
EOH
	
	return $edit_paragraphes;
}

sub custom_mailing_preview
{
	my $id = $_[0];
	my $colg = $_[1];
	my %page = %{$_[2]};
			
	return <<"EOH";
		<a href="migcms_view.pl?id_page=$page{id}&mailing=y&lg=1" data-original-title="Aperçu" data-placement="bottom" class="btn btn-default" target="_blank">
			<i class="fa fa-eye fa-fw" data-original-title="" title=""></i>  
		</a>
EOH
}

sub custom_mailing_send
{
	my $id = $_[0];
	my $colg = $_[1];
	my %page = %{$_[2]};

	my %migcms_page = sql_line({table=>'migcms_pages',where=>"id='$id'"});
	# my %script_rec = sql_line({table=>'scripts',where=>"url LIKE '%adm_migcms_mailings_sendings.pl?%'"});
	my %script_rec = sql_line({table=>'scripts',where=>"url LIKE '%adm_migcms_pages_newsletters.pl?%'"});
	if($script_rec{id} eq '')
	{
		$script_rec{id} = get_quoted('sel');
	}
	my $link = 'adm_migcms_mailings_sendings.pl?&sw=prepare_form&id_migcms_page='.$page{id}.'&sel='.$script_rec{id}.'&mailing_basehref='.$migcms_page{mailing_basehref};		

	
	my $apercu = <<"EOH";
		<a class="btn btn-default" href="$link" data-original-title="Envoyer la newsletter" target="" data-placement="bottom">
			<i class="fa fa-paper-plane fa-fw" data-original-title="" title=""></i>
		</a>
EOH
	
	return $apercu;
}

sub custom_mailing_archives
{
	my $id = $_[0];
	my $colg = $_[1];
	my %page = %{$_[2]};
	
	my %script_rec = sql_line({table=>'scripts',where=>"url LIKE '%adm_migcms_mailings_sendings.pl?%'"});
	my $link = 'adm_migcms_mailings_sendings.pl?&id_migcms_page='.$page{id}.'&sel='.$script_rec{id};		
	
	my $acces = <<"EOH";
		<a class="btn btn-default" href="$link" data-original-title="Envois" target="" data-placement="bottom">
			<i class="fa fa-archive fa-fw" data-original-title="" title=""></i>  
		</a>
EOH

	return $acces;

}

sub custom_mailing_statistiques
{
	my $id = $_[0];
	my $colg = $_[1];
	my %page = %{$_[2]};
	$script_rec{id} = get_quoted('sel');
	my $url = 'adm_migcms_dashboard.pl?mailing=y&id_dashboard=3&id_migcms_page='.$page{id}.'&sel='.$script_rec{id};
	
	my $acces = <<"EOH";
		<a class="btn btn-default" href="$url" data-original-title="Statistiques de la newsletter" data-placement="bottom">
			<i class="fa fa-bar-chart" aria-hidden="true"></i>
		</a>
EOH

	return $acces;

}

sub get_campaign
{
	my $dbh = $_[0];
    my $id = $_[1];
	
	my %page = sql_line({table=>'migcms_pages',select=>"*",where=>"id='$id'"});
	my %campaign = sql_line({table=>'mailing_campaigns',select=>"campaign_name",where=>"id='$page{mailing_id_campaign}'"});

	return $campaign{campaign_name};
}

sub get_sender
{
	my $dbh = $_[0];
    my $id = $_[1];
	
	my %page = sql_line({table=>'migcms_pages',select=>"*",where=>"id='$id'"});
	
	my $sender = $page{mailing_from}." (".$page{mailing_from_email}.")";

	return $sender;
}

sub get_nbr_sendings
{
	my $dbh = $_[0];
    my $id = $_[1];
	
	my %sendings = sql_line({table=>'mailing_sendings',select=>"COUNT(id) as nbr",where=>"id_migcms_page='$id'"});
	
	my $nbr_sendings = '<center><span class="badge">'.$sendings{nbr}.'</span></center>';

	return $nbr_sendings;
}


sub duplicate_page
{
	my $id_page = $_[1];
		
	my %migcms_page = read_table($dbh,'migcms_pages',$id_page);
	my $title = get_traduction({id=>$migcms_page{id_textid_name},id_language=>$colg});
	
	my $duplicated_id_migcms_page = duplicate_simple_record($dbh,$id_page);
	
	#changer la page dupliquée pour la rendre invisible
	$stmt = "UPDATE migcms_pages SET visible = 'n' WHERE id = '$duplicated_id_migcms_page'";
	execstmt($dbh,$stmt);

	%dm_dfl_parags = (
	'01/id_template' => 
	{
		'title'=>'Template de contenu',
		'mandatory'=>{"type" => 'not_empty' },
		'fieldtype'=>'listboxtable',
		# 'legend'=>"Correspond à la mise en forme graphique de ce paragraphe",
		'lbtable'=>'templates',
		'lbkey'=>'id',
		'lbdisplay'=>"name",
		'tab'=>1,
		'lbwhere'=>"type = '$type_parag'" ,
	}     
	,
	'11/id_textid_title' => 
	{
		'title'=>'Titre',
		'tab'=>1,
		'fieldtype'=>'text_id',
	}
	,
	'22/id_textid_text_1' => 
	{
		'title'=>'Contenu',
		'tab'=>1,
		'fieldtype'=>'text_id',
	} 
	,
	'23/id_textid_text_2' => 
	{
		'title'=>'Contenu',
		'tab'=>1,
		'fieldtype'=>'text_id',
	} 
	,
	'24/id_textid_text_3' => 
	{
		'title'=>'Contenu',
		'tab'=>1,
		'fieldtype'=>'text_id',
	} 
	,
	'25/id_textid_text_4' => 
	{
		'title'=>'Contenu',
		'tab'=>1,
		'fieldtype'=>'text_id',
	} 
	,
	'32/id_textid_textwysiwyg_1' => 
	{
		'title'=>'Contenu',
		'tab'=>1,
		'fieldtype'=>'text_id',
	} 
	,
	'33/id_textid_textwysiwyg_2' => 
	{
		'title'=>'Contenu',
		'tab'=>1,
		'fieldtype'=>'text_id',
	} 
	,
	'34/id_textid_textwysiwyg_3' => 
	{
		'title'=>'Contenu',
		'tab'=>1,
		'fieldtype'=>'text_id',
	} 
	,
	'35/id_textid_textwysiwyg_4' => 
	{
		'title'=>'Contenu',
		'tab'=>1,
		'fieldtype'=>'text_id',
	}
	,
	'21/id_textid_parag' => 
	{
		'title'=>'Contenu',
		'tab'=>1,
		'fieldtype'=>'textarea_id_editor',
	}  
	,
	'84/do_not_resize'=> 
	{
		'title'=>"Ne pas redimensionner les photos",
		'tab'=>2,
		'default_value'=>'n',
		'fieldtype'=>'checkbox',
		'disable_add'=>1,
	}
	,
	'83/fichiers'=> 
	{
		'title'=>"Photos",
		'tab'=>2,
		'fieldtype'=>'files_admin',
		'disable_add'=>1,
	}
	,
	'99/id_page' => 
	{
		'title'=>'Page',
		'tab'=>2,
		'fieldtype'=>'text',
		'data_type'=>"hidden"
	}
	);
	
	#dupliquer les paragraphes de la page
	my @parags = sql_lines({table=>'parag',where=>"id_page ='$id_page'",ordby=>"ordby,id"});
	foreach $parag (@parags)
	{
		my %parag = %{$parag};
		# my $duplicated_id_parag = duplicate_simple_record($dbh,$parag{id},'reverse_ordby','parag',0,\%dm_dfl_parags,'PAR');
		my $duplicated_id_parag = duplicate_simple_record($dbh,$parag{id},'','parag',0,\%dm_dfl_parags,'PAR');
	
		#lier les paragraphes dupliques à la page dupliquee
		$stmt = "UPDATE parag SET id_page = '$duplicated_id_migcms_page' WHERE id = '$duplicated_id_parag'";
		execstmt($dbh,$stmt);
	}	
	
	dm_cms::migcms_build_compute_urls();

	exit;
}



