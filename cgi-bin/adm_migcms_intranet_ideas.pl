#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;
#
#use fwlayout;
#use fwlib;
# migc modules
#
#         # migc translations
#
#
use migcrender;

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###############################################################################################
####################################	CODE DU PROGRAMME		######################################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
$dbh_data = $dbh;

my $htaccess_ssl = $config{rewrite_ssl};
my $htaccess_protocol_rewrite = "http";
if($htaccess_ssl eq 'y') {
  $htaccess_protocol_rewrite = "https";
}

my $id_page = get_quoted('id_page'); 
$dm_cfg{one_button} = 0;
$dm_cfg{dbh} = $dbh_data;
$dm_cfg{disable_mod} = 'n';   
$dm_cfg{disable_buttons} = 'n';
$dm_cfg{hide_id} = 1;
$dm_cfg{nolabelbuttons} = 'y';

$dm_cfg{enable_search} = 1;
$dm_cfg{enable_multipage} = 1;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{no_drag_sort} = 1;
$dm_cfg{migcms_parag_inline_edit} = 0;

$dm_cfg{wherep} = $dm_cfg{wherel} = "";
$dm_cfg{table_name} = "intranet_ideas";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{wherep_ordby} = "";
$dm_cfg{default_ordby} = " id ";

$dm_cfg{get_form_ref} = \&get_form;
$dm_cfg{get_view_ref} = \&get_view;
$dm_cfg{get_and_check_ref} = \&get_and_check;
$dm_cfg{before_del_ref} = \&before_del;
$dm_cfg{table_width} = 850;
$dm_cfg{fieldset_width} = 850;
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_$dm_cfg{table_name}.pl?";
$dm_cfg{after_mod_ref} = \&update_embed;
$dm_cfg{after_add_ref} = \&add_embed;
$dm_cfg{col_id} = 'id';
$dm_cfg{page_title} = 'IDbox';
$dm_cfg{add_title} = "Ajouter une idée";
$dm_cfg{page_func} = 'list_intranet_ideas';

# my %page = sql_line({debug => 0,table=>'migcms_pages',where=>"id='$id_page'"});
my ($page_title,$dum) = get_textcontent($dbh,$page{id_textid_name});
$dm_cfg{bread_title} =<< "EOH";

$page_title <span class="divider"></span> 

EOH

$dm_cfg{hiddp}=<<"EOH";
<input type="hidden" name="id_page" value="$id_page" />
EOH

$config{logfile} = "trace.log";

%statuts = (
'prospect'=>'Prospect',
'commande'=>'Commande',
'facturer'=>'Facturé',
'archive'=>'Archivé'
);

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (

	  '01/nom' => 
      {
       'title'=>'Titre',
       'fieldtype'=>'text',
      }
	  ,
	  '20/descr' => 
      {
       'title'=>'Description',
       'fieldtype'=>'textarea_editor',
      }
	  
	);
	

%dm_display_fields = (
		);


%dm_lnk_fields = (

		);

%dm_mapping_list = (

);

%dm_filters = (
		);

$dm_cfg{help_url} = "http://www.bugiweb.com";

# this script's name

$sw = $cgi->param('sw') || "list";

see();

my @fcts = qw(
			add_form
			mod_form
			list
			add_db
			mod_db
			del_db
			effect_gallery
      ajax_save_parag
	  duplicate_projet
      ajax_save_elt
	  ajax_save_liaison
		);

if (is_in(@fcts,$sw)) 
{ 
    dm_init();
    &$sw();
    $gen_bar = get_gen_buttonbar();
    $spec_bar = get_spec_buttonbar($sw,"");

    $migc_output{content} .= $dm_output{content};
    $migc_output{title} = $dm_output{title}.$migc_output{title};
    
#     my $id_banner_zone=get_quoted('id');
#     my $markup=get_markup($id_banner_zone);
    
    my $suppl_js=<<"EOH";
EOH
      
    print migc_app_layout($suppl_js.$migc_output{content},$migc_output{title},"",$gen_bar,$spec_bar);
}

            
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub get_and_check
{
	my %item; 
  my $op = $_[0];
#  use Data::Dumper;

  
	foreach $key (keys(%dm_dfl))
	{ 
		my ($num,$field) = split(/\//,$key);
		
		$item{$field} = get_quoted($field);

		 if ($dm_dfl{$key}{fieldtype} eq "text_id" || 
         $dm_dfl{$key}{fieldtype} eq "textarea_id" || $dm_dfl{$key}{fieldtype} eq "textarea_id_editor")
      {        
       %item = %{update_textid_field($dbh,$field,$op,\%item)};
#         see(\%item);

      }
      elsif ($dm_dfl{$key}{fieldtype} eq "file")
      { 
             
             if($datadir_config{upload_path} eq "")
             {
                $datadir_config{upload_path}=$upload_path;
             }
             
             
             
             %item = %{update_file_field_admin($dbh,$field,$op,\%item,$datadir_config{upload_path},$default_small_height,$default_small_width,$default_medium_width,$default_medium_height,$default_mini_width,$default_mini_height)};

            
             
             if ($item{$field} eq "") {delete $item{$field};} elsif ($item{$field} eq " "){$item{$field}="";} 
      }
      elsif ($dm_dfl{$key}{fieldtype} eq "pic")
      { 
           $item{$field} = $cgi->param($field);
           %item = %{update_pic_field_admin_fixed($dbh,$field,$op,\%item,$datadir_config{upload_path},$default_small_height,$default_small_width,$default_medium_width,$default_medium_height,$default_mini_width,$default_mini_height,"fixed_height")};
           if ($item{$field} eq "") {delete $item{$field};}
      }
      
		if (defined $dm_dfl{$key}{mandatory})
		{
			if (!check_field_value($item{$field}, $dm_dfl{$key}{mandatory}{type}, \@{$dm_dfl{$key}{mandatory}{params}}))
			{
				dm_check_error($dm_dfl{$key}{title});
			}
		}
  }
	return (\%item);	
}


#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub get_form
{
	my %item = %{$_[0]};
	
	my $form = build_form(\%dm_dfl,\%item);



	return $form;
}
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub get_view
{
	my %item = %{$_[0]};
	my $form = build_view(\%dm_dfl,\%item);

	return $form;
}
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub before_del
{
  my $dbh = $_[0];
  my $id = $_[1];
  
  
}

sub add_embed
{
  my $dbh = $_[0];
  my $id = $_[1];
  
}

sub update_embed
{
  my $dbh = $_[0];
  my $id = $_[1];
}

sub ajax_save_parag
{
    see();
    my $id = get_quoted('id');
    my $type = get_quoted('type');
    my $content = get_quoted('content');
    my $colg = get_quoted('colg');
    my %parag = sql_line({table=>'parag',where=>"id='$id'"});
#     $content =~ s/\'/\\\'/g;
    
    if($type eq 'content')
    {
        my $stmt = "UPDATE txtcontents SET lg$colg='$content' WHERE id ='$parag{id_textid_parag}'";
        execstmt($dbh,$stmt);
    }
    elsif($type eq 'title')
    {
        my $stmt = "UPDATE txtcontents SET lg$colg='$content' WHERE id ='$parag{id_textid_title}'";
        execstmt($dbh,$stmt);
    }
}




#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub parag_rendu
{
  my $dbh = $_[0];
  my $id = $_[1];
  my %d = %{$_[3]};

  my $parag = render_parag({id=>$id,lg=>$lg});
  
  my $rendu = <<"EOH";
  <div class="mig_parag_container" id="$id">
      $parag
  </div>
EOH

  return $rendu;
}


sub excel_import
{
	see();

use Encode;
  my $modele='../commandes.xls';
  
  #read excel model
  my $parser   = Spreadsheet::ParseExcel->new();
  my $workbook_from = $parser->Parse($modele);
  my $worksheet_from=$workbook_from->worksheet(0);

  		$stmt = "TRUNCATE intranet_projets";
		$cursor = $dbh2->prepare($stmt);
		$cursor->execute || suicide($stmt);
		
		$stmt = "TRUNCATE intranet_projets_details";
		$cursor = $dbh2->prepare($stmt);
		$cursor->execute || suicide($stmt);
 
  foreach my $ligne (1 .. 500) 
  {
     
	  my $date = '';
	  my $montant_net = '';
	  my $nom_projet = '';
	  my $lignes = '';
	  my $nom_client = '';
	  my $nom_revendeur = '';
	  my $montant_brut = '';
	  my $commission = '';
	  my $statut = 'commande';
	  
    
	my $colonne='A';
    my $cell = $worksheet_from->{Cells}[$ligne][convert_xls_col($colonne)];  
    if($cell ne "")
    {
           $data= Encode::encode( "utf8", $cell->Value);         
           $data =~ s/\'/\\\'/g;
		   $date = trim($data);	   
    }
	my $colonne='B';
    my $cell = $worksheet_from->{Cells}[$ligne][convert_xls_col($colonne)];  
    if($cell ne "")
    {
           $data= Encode::encode( "utf8", $cell->Value);         
           $data =~ s/\'/\\\'/g;
		   $montant_net = trim($data);	   
    }
    my $colonne='C';
    my $cell = $worksheet_from->{Cells}[$ligne][convert_xls_col($colonne)];  
    if($cell ne "")
    {
           $data= Encode::encode( "utf8", $cell->Value);         
           #get format******************************************************
           my $format_from= $cell->{Format};
           my $font_from= $format_from->{Font};
           my $color_from= $parser->ColorIdxToRGB($font_from->{Color});
           $data =~ s/\'/\\\'/g;
		   
		   
		   if($color_from eq 'FFFFFF')
		   {
				$statut = 'commande';
		   }
		   elsif($color_from eq'FF0000')
		   {
				$statut = 'facturer';
		   }
		   elsif($color_from eq'800080')
		   {
				$statut = 'archive';
		   }
		   else
		   {
				$statut = 'prospect';
		   }
		   $nom_projet = trim($data);
		   
		   
		   
    }
	my $colonne='D';
    my $cell = $worksheet_from->{Cells}[$ligne][convert_xls_col($colonne)];  
    if($cell ne "")
    {
           $data= Encode::encode( "utf8", $cell->Value);         
		   $lignes = trim($data);	   
    }
	my $colonne='E';
    my $cell = $worksheet_from->{Cells}[$ligne][convert_xls_col($colonne)];  
    if($cell ne "")
    {
           $data= Encode::encode( "utf8", $cell->Value);         
           $data =~ s/\'/\\\'/g;
		   $nom_client = trim($data);	   
    }
	my $colonne='F';
    my $cell = $worksheet_from->{Cells}[$ligne][convert_xls_col($colonne)];  
    if($cell ne "")
    {
           $data= Encode::encode( "utf8", $cell->Value);         
           $data =~ s/\'/\\\'/g;
		   $nom_revendeur = trim($data);	   
    }
	my $colonne='G';
    my $cell = $worksheet_from->{Cells}[$ligne][convert_xls_col($colonne)];  
    if($cell ne "")
    {
           $data= Encode::encode( "utf8", $cell->Value);         
           $data =~ s/\'/\\\'/g;
		   $montant_brut = trim($data);	   
    }
	my $colonne='H';
    my $cell = $worksheet_from->{Cells}[$ligne][convert_xls_col($colonne)];  
    if($cell ne "")
    {
           $data= Encode::encode( "utf8", $cell->Value);         
           $data =~ s/\'/\\\'/g;
		   $commission = trim($data);	   
    }
	print "<br /> <h2>$nom_projet</h2>";
	  
	my %projet = 
	(
		'nom_client' => $nom_client,
		'nom_revendeur' =>$tnom_revendeur,
		'date_debut' => $date,
		'nom' => $nom_projet,
		'statut' => $statut,
		'montant_brut' => $montant_brut,
		'commission' => $commission,
		'montant_net' => $montant_net
	);
	my $id_projet = sql_set_data({dbh=>$dbh2,table=>'intranet_projets',data=>\%projet, where=>"nom='$projet{nom}'"});
	
	my @lines = split(/\r*\n/,$lignes);
	# see();
	use Data::Dumper;
	# print Dumper \@lines;
	
	foreach $line (@lines)
	{
		# print "<h3>$line</h3>";
		my ($date,$content) = split(/\s?\:\s/,$line);
		
		my ($j,$m,$a) = split(/\-/,$date);
		$date_amj = $a.'-'.$m.'-'.$j;

		
		if($a > 0 && $m > 0 && $j > 0)
		{
		}
		else
		{
			$content = $line;
			$date_amj = '';
		}
		
		if($date ne '' && $content eq '')
		{
			$content = $date;
			$date = '';
		}
		
		$content =~ s/•/*/g;
		$content =~ s/™/tm/g;
		# $content =~ s/\?/\./g;
		# $content =~ s/\!/\./g;
		 
		
		$content =~ s//tm/g;
		# $content =~ s/o/*/g;
		$content =~ s/–/-/g;
		$content =~ s/–/-/g;
	
		
		$content = simplifier($content,'with_spaces','','');
		$date_amj =~ s/\'/\\\'/g;
		$content =~ s/\'/\\\'/g;
		
				print "<br /> <b>$date_amj</b> $content <hr />";
		my %projet_detail = 
		(
			'id_intranet_projet' => $id_projet,
			'date' =>$date_amj,
			'texte' => $content
		);
		
		my $id_projet_detail = sql_set_data({debug=>0,debug_results=>0,dbh=>$dbh2,table=>'intranet_projets_details',data=>\%projet_detail, where=>""});
	}

      
   }
    
   exit; 
  
       
}

sub convert_xls_col
{
     my $col = $_[0];
     if (length($col) > 1) 
     {
         my $sl = chop $col;
         return ((((ord($col) - 65) + 1) * 26) + (ord($sl) - 65)); 
     }
     return (ord($col) - 65);
}	
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

sub simplifier
{
    my $nom = $_[0];
    if($_[1] eq 'with_spaces')
    {
        if($_[2] eq 'plus_spaces')
        {
            if($_[3] eq 'avec_accents')
            {
                $nom =~ s/[^a-zA-Z0-9\séàùèâçêîûôïöë\-\:\/]+/ /g;
            }
            else
            {
                $nom =~ s/[^a-zA-Z0-9\s]+/ /g;
            }
        }
        else
        {
            $nom =~ s/[^a-zA-Z0-9\séàùèâçêîûôïöë\-\:\']+//g;
        }
    }
    else
    {
        $nom =~ s/[^a-zA-Z]+//g;
    }
    return $nom;
}

sub ajax_save_liaison
{
	see();
	my $bugi = get_quoted('bugi');
	my $id = get_quoted('id');
	my $valeur = get_quoted('valeur');
	
	$stmt = "UPDATE intranet_projets_details SET $bugi='$valeur' WHERE id = '$id' ";
	execstmt($dbh_data,$stmt);
	
	exit;
}

sub ajax_save_type_detail
{
	see();
	my $type = get_quoted('type');
	my $id = get_quoted('id');
	
	if($type eq 'technique')
	{
		$stmt = "UPDATE intranet_projets_details SET technique='y' WHERE id = '$id' ";
		execstmt($dbh_data,$stmt);
	}
	else
	{
		$stmt = "UPDATE intranet_projets_details SET technique='n' WHERE id = '$id' ";
		execstmt($dbh_data,$stmt);
	}
	exit;
}

sub ajax_get_projects
{
	my $prospect = get_quoted('prospect');
	my $commande = get_quoted('commande');
	my $facturer = get_quoted('facturer');
	my $archive = get_quoted('archive');
	# see();
	
	my @where = ();
	if($prospect eq 'checked')
	{
		push @selects, " statut = 'prospect' ";
	}
	if($commande eq 'checked')
	{
		push @selects, " statut = 'commande' ";
	}
	if($facturer eq 'checked')
	{
		push @selects, " statut = 'facturer' ";
	}
	if($archive eq 'checked')
	{
		push @selects, " statut = 'archive' ";
	}
	my $where = join(" OR ",@selects);
	if($where eq '')
	{
		$where = 0;
	}
      	
	my $list_projets = '';
	
	my $employe = get_quoted('employe');
	my $where_employe = '';
	if($employe ne '')
	{
		$where_employe = " AND id IN (select id_intranet_projet from intranet_projets_details where texte LIKE '%$employe%' )";
	}
	
	my $liaison = get_quoted('liaison');
	my $where_liaison = '';
	if($liaison ne '')
	{
		$where_liaison = " AND id IN (select id_intranet_projet from intranet_projets_details where $liaison = 'y')";
	}
	
	my @prs = sql_lines({dbh=>$dbh2,table=>"intranet_projets pr",where=>"nom != '' AND ($where) $where_employe $where_liaison", ordby=>"nom"});
	foreach $pr (@prs)
	{
		my %pr = %{$pr};
		
		
		$where_liaison_detail = " AND id_intranet_projet IN (select id_intranet_projet from intranet_projets_details where id=d.id AND $liaison = 'y')";
		if($liaison eq '')
		{
			$where_liaison_detail =  '';
		}
		$where_employe_detail = " AND id_intranet_projet IN (select id_intranet_projet from intranet_projets_details where id=d.id AND texte LIKE '%$employe%' )";
		if($employe eq '')
		{
			$where_employe_detail = '';
		}
		my %pr_detail = sql_line({debug=>0,dbh=>$dbh2,select => 'DATEDIFF(date_limite,NOW()) as nbj', table=>"intranet_projets_details d",where=>"id_intranet_projet = '$pr{id}' AND date_limite != '0000-00-00'  $where_employe_detail $where_liaison_detail", ordby=>"date_limite desc"});	
		
		# if($employe ne '')
		# {
		# if($pr_detail{nbj} >= 15)
		# {
			# $pr_detail{nbj} = '<span style="color:green" class="pull-right"> '.$pr_detail{nbj}.' jour(s)</span>';
		# }
		# elsif($pr_detail{nbj} < 15 && $pr_detail{nbj} > 0)
		# {
			# $pr_detail{nbj} = '<span style="color:orange" class="pull-right"> '.$pr_detail{nbj}.' jour(s)</span>';
		# }
		# elsif($pr_detail{nbj} < 0)
		# {
			# $pr_detail{nbj} = '<span style="color:red" class="pull-right"><b>'.$pr_detail{nbj}.' jour(s)</b></span>';
		# }
		# }
		 $list_projets .=<< "EOH";
		 <a rel="$pr{statut}"  class="list-group-item $pr{statut} line_project_$pr{id}" id="$pr{id}" href="#"><span>$pr{nom}</span> $pr_detail{nbj}</a>
EOH
	}
	print $list_projets;
	exit;
}

sub ajax_change_statut
{
	
	see();
	my $id_projet = get_quoted('id_project');
	my $statut = get_quoted('statut');
	
	$stmt = "UPDATE intranet_projets SET statut='$statut' WHERE id = '$id_projet' ";
	execstmt($dbh_data,$stmt);
	exit;
}

sub ajax_add_idea_line
{
	see();
	my $id_idea = get_quoted('id_idea');

	my $new_detail = get_quoted('new_detail');
	my $new_date = trim(get_quoted('new_date'));

	$new_date = to_sql_date($new_date);
	if(trim(get_quoted('new_date') eq ''))
	{
		$new_date = 'NOW()';
	}
	
	my %rec = (
		id_intranet_idea	=> $id_idea,
		texte => $new_detail,
		date => $new_date
	);
	
	
	inserth_db($dbh_data,'intranet_idea_lines',\%rec);
	
	
	exit;
}

sub ajax_save_detail
{
	see();
	my $id = get_quoted('id');
	my $content = get_quoted('content');
	
	my %rec = (
		texte => $content,
	);
    updateh_db($dbh2,"intranet_idea_lines",\%rec,'id',$id);
	
	
	exit;
}


sub ajax_get_details
{
	my $id_idea = get_quoted('id_idea');
	my %pr = sql_line({dbh=>$dbh2,table=>"intranet_ideas",where=>"id = '$id_idea' "});
	my @intranet_idea_lines = sql_lines({dbh=>$dbh2,table=>"intranet_idea_lines",ordby=>'id desc',where=>"id_intranet_idea='$id_idea'"});
	
	my $list = <<"EOH";
	
EOH
	
	my @months = ("","Janvier","Février","Mars","Avril","Mai","Juin","Juillet","Août","Septembre","Octobre","Novembre","Décembre"); 
	
    foreach $intranet_idea_lines (@intranet_idea_lines)
    {
        my %intranet_idea_lines = %{$intranet_idea_lines};
		
		my ($date,$time) = split(/ /,$intranet_idea_lines{date});
		my ($yyyy,$mm,$dd) = split (/-/,$date); 
		my ($h,$min,$sec) = split (/:/,$time); 
		
		
		# my ($a,$m,$j) = split(/\-/,$intranet_idea_lines{date});
		my $la_date = $dd.' '.$months[$mm].' '.$yyyy.' à '.$h.'h'.$min;
		if($yyyy > 0 && $mm > 0 && $dd >0)
		{
		}
		else
		{
			$la_date = '';
		}
		
		
		$list .= <<"EOH";
			<article class="timeline-item " >
				<div class="timeline-desk" style="width:1500px;">
					<div class="panel $pr{statut}"   >
						<div class="panel-body" id="$intranet_idea_lines{id}">
							<span class="arrow $pr{statut}-arrow" ></span>
							<span class="timeline-icon"></span>
							<h1 style="">$la_date
							
							
							
						
							
							</h1>
							
							
							
							
							<span class="timeline-date"></span>
							<div class="timeline-content">
							$intranet_idea_lines{texte}
							</div>
							<div class="dropdown_container">
							
								
								
							</div>
						</div>
					</div>
				</div>
            </article> 
EOH
	}
	# see();
	
	$list .= <<"EOH";
	
EOH
	
	print $list;
	exit;
}

sub duplicate_projet
{
		my $id_projet = get_quoted('id_projet');
		
		#read projet
		my %projet = read_table($dbh2,'intranet_projets',$id_projet);
		$projet{nom_client} =~ s/\'/\\'/g;
		$projet{nom_revendeur} =~ s/\'/\\'/g;
		$projet{nom} =~ s/\'/\\'/g;
		
		my %new_projet = 
		(
			'nom_client' => $projet{nom_client},
			'nom_revendeur' =>$projet{nom_revendeur},
			'date_debut' => $projet{date_debut},
			'nom' => $projet{nom},
			'statut' => $projet{statut},
			'montant_brut' => $projet{montant_brut},
			'commission' => $projet{commission},
			'montant_net' => $projet{montant_net},
		);
		
		#insert projet
		my $new_id_projet = sql_set_data({dbh=>$dbh2,table=>'intranet_projets',data=>\%new_projet, where=>""});	
		
		#read posts
		my @det = sql_lines({dbh=>$dbh2,table=>'intranet_projets_details',where=>"id_intranet_projet='$id_projet'"});
		foreach $projet_detail (@det)
		{
			my %projet_detail = %{$projet_detail};
		
			#insert posts
			$projet_detail{date} =~ s/\'/\\'/g;
			$projet_detail{texte} =~ s/\'/\\'/g;
			my %new_projet_detail = 
			(
				'id_intranet_projet' => $new_id_projet,
				'date' =>$projet_detail{date},
				'texte' => $projet_detail{texte}
			);

			my $id_projet_detail = sql_set_data({debug=>0,debug_results=>0,dbh=>$dbh2,table=>'intranet_projets_details',data=>\%new_projet_detail, where=>""});
		}
}