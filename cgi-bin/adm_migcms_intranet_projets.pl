#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;
# #
# #use fwlayout;
# #use fwlib;
# migc modules
# #
# #         # migc translations
# #
# #
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
$dm_cfg{table_name} = "intranet_projets";
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
$dm_cfg{page_title} = 'Réunion de projets';
$dm_cfg{add_title} = "Ajouter un projet";
$dm_cfg{page_func} = 'list_intranet_projets';

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
      # '10/date_debut' => 
      # {
       # 'title'=>'Date début',
       # 'fieldtype'=>'text',
       # 'data_type'=>"date"
      # }
	  # ,
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (

	  '20/nom' => 
      {
       'title'=>'Nom du projet',
       'fieldtype'=>'text',
      }
	  ,
	  '30/nom_client' => 
      {
       'title'=>'Nom client',
       'fieldtype'=>'text',
      }
	  ,
	  '40/nom_revendeur' => 
      {
       'title'=>'Nom revendeur',
       'fieldtype'=>'text',
      }
	  ,
		"50/statut"=>
		{
					'title'=>"Statut",
			  'fieldtype'=>'listbox',
			  'data_type'=>'btn-group',
			  'fieldvalues'=>\%statuts,
			  'default_value'=>'prospect',
	}
	  ,
	  '60/montant_brut' => 
      {
       'title'=>'Montant Brut',
       'fieldtype'=>'text',
      }
	  ,
	  '70/commission' => 
      {
       'title'=>'Commission',
       'fieldtype'=>'text',
      }
	  ,
	  '80/montant_net' => 
      {
       'title'=>'Montant net',
       'fieldtype'=>'text',
      }
	);
	
# ,
		 # '30/id_client_final' => 
		  # {
		   # 'title'=>'Client',
		   # 'fieldtype'=>'listboxtable',
		   # 'lbtable'=>'cli ',
		   # 'lbkey'=>'id',
		   # 'lbdisplay'=>"name_client",
		   # 'lbwhere'=>"" ,
			 # 'search' => 'n',
		   # 'mandatory'=>{"type" => 'not_empty'},
		  # }
		  # ,
		  # '40/id_revendeur' => 
		  # {
		   # 'title'=>'Revendeur',
		   # 'fieldtype'=>'listboxtable',
		   # 'lbtable'=>'cli ',
		   # 'lbkey'=>'id',
		   # 'lbdisplay'=>"name_client",
		   # 'lbwhere'=>"" ,
		  # 'search' => 'n',
		  # }
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
	  ajax_save_type
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

sub ajax_save_type
{
	see();
	my $type = get_quoted('type');
	my $id = get_quoted('id');
	my $valeur = get_quoted('valeur');
	
	$stmt = "UPDATE intranet_projets_details SET $type='$valeur' WHERE id = '$id' ";
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
	
	my %liste_projets = ();
	my @prs = sql_lines({debug=>0,dbh=>$dbh2,table=>"intranet_projets pr",where=>"nom != '' AND ($where) $where_employe $where_liaison", ordby=>"nom"});
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
		my %pr_detail = sql_line({debug=>0,dbh=>$dbh2,select => 'DATEDIFF(date_limite,NOW()) as nbj', table=>"intranet_projets_details d",where=>"id_intranet_projet = '$pr{id}' AND date_limite != '0000-00-00'  $where_employe_detail $where_liaison_detail", ordby=>"date_limite asc"});	
		
		my $detail_nbj = '';
		if($pr_detail{nbj} eq '')
		 {
			$pr_detail{nbj} = 999;
		 }
		if($liaison ne '')
		{
			if($pr_detail{nbj} == 999)
			{
				$detail_nbj = '';
			}
			elsif($pr_detail{nbj} >= 15)
			{
				$detail_nbj = '<span style="color:green" class="pull-right"> '.$pr_detail{nbj}.' jour(s)</span>';
			}
			elsif($pr_detail{nbj} < 15 && $pr_detail{nbj} > 0)
			{
				$detail_nbj = '<span style="color:orange" class="pull-right"> '.$pr_detail{nbj}.' jour(s)</span>';
			}
			elsif($pr_detail{nbj} <= 0)
			{
				$detail_nbj = '<span style="color:red" class="pull-right"><b>'.$pr_detail{nbj}.' jour(s)</b></span>';
			}
		}
		 
		 
		 my $line_info_projet = <<"EOH";
			<a rel="$pr{statut}"  class="list-group-item $pr{statut} line_project_$pr{id}" id="$pr{id}" href="#"><span>$pr{nom}</span> $detail_nbj</a>
EOH
		 if($pr_detail{nbj} < 0)
		 {
			$pr_detail{nbj} = 0;
		 }
		 
		 $liste_projets{1000 + $pr_detail{nbj}} .= $line_info_projet;
		 $list_projets .= $line_info_projet;		
	}

	# if(scalar keys %liste_projets > -1)
	# {
		# foreach $liste_projets_key (sort keys %liste_projets)
		# {
			# print $liste_projets{$liste_projets_key};
		# }
	# }
	# else
	# {
		print $list_projets;
	# }
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

sub ajax_add_detail
{
	see();
	my $id_projet = get_quoted('id_project');
	my $statut = get_quoted('statut');
	my $new_detail = get_quoted('new_detail');
	my $new_date = trim(get_quoted('new_date'));
	my $new_date_limite = trim(get_quoted('new_date_limite'));
	$new_date = to_sql_date($new_date);
	$new_date_limite = to_sql_date($new_date_limite);
	if(trim(get_quoted('new_date') eq ''))
	{
		$new_date = 'NOW()';
	}
	# $new_detail =~ s/\'/\\\'/g;
	
	my %rec = (
		id_intranet_projet	=> $id_projet,
		texte => $new_detail,
		date => $new_date,
		date_limite => $new_date_limite,
		detail_id_user => $user{id},
	);
	
	inserth_db($dbh_data,'intranet_projets_details',\%rec);
	
	
	exit;
}

sub ajax_save_detail
{
	see();
	my $id = get_quoted('id');
	my $content = get_quoted('content');
	# $content =~ s/\'/\\\'/g;
	
	
	my $from = 'ALEXIS';
	my $to = '<span class="badge">ALEXIS</span>';
	$content =~ s/$to/$from/gi;
	
	my $from = 'freddy';
	my $to = '<span class="badge">FREDDY</span>';
	$content =~ s/$to/$from/gi;

	my $from = 'stef';
	my $to = '<span class="badge">STEF</span>';
	$content =~ s/$to/$from/gi;
	
	my $from = 'stephane';
	my $to = '<span class="badge">STEPHANE</span>';
	$content =~ s/$to/$from/gi;
	
	my $from = 'romain';
	my $to = '<span class="badge">ROMAIN</span>';
	$content =~ s/$to/$from/gi;

	my $from = 'alain';
	my $to = '<span class="badge">ALAIN</span>';
	$content =~ s/$to/$from/gi;

	my $from = 'greg';
	my $to = '<span class="badge">GREG</span>';
	$content =~ s/$to/$from/gi;
	
	
	# my $from = '<br>';
	# my $to = '\n';
	# $content =~ s/$to/$from/gi;
	
	my %rec = (
		texte => $content,
	);
    updateh_db($dbh2,"intranet_projets_details",\%rec,'id',$id);
	
	
	exit;
}


sub ajax_get_details
{
	my $id_projet = get_quoted('id_project');
	my $show_suivi = get_quoted('show_suivi');
	my $show_technique = get_quoted('show_technique');
	
	my %pr = sql_line({dbh=>$dbh2,table=>"intranet_projets",where=>"id = '$id_projet' "});
	my $where_type = '';
	if($show_technique eq 'checked' && $show_suivi eq 'checked')
	{
		#tous
	}
	elsif($show_technique eq 'checked' && $show_suivi ne 'checked')
	{
		#technique seulement
		$where_type = " AND technique = 'y' ";
	}
	elsif($show_technique ne 'checked' && $show_suivi eq 'checked')
	{
		#technique seulement
		$where_type = " AND technique != 'y' ";
	}
	
	my @intranet_projets_details = sql_lines({dbh=>$dbh2,table=>"intranet_projets_details",ordby=>'date desc, id desc',where=>"id_intranet_projet='$id_projet' $where_type"});
	
	my $list = <<"EOH";
	
EOH
	
	my @months = ("","Janvier","Février","Mars","Avril","Mai","Juin","Juillet","Août","Septembre","Octobre","Novembre","Décembre"); 
	my $i = 0;
    foreach $intranet_projet_detail (@intranet_projets_details)
    {
        my %intranet_projet_detail = %{$intranet_projet_detail};
		my ($a,$m,$j) = split(/\-/,$intranet_projet_detail{date});
		my $la_date = $j.' '.$months[$m].' '.$a;
		if($a > 0 && $m > 0 && $j >0)
		{
		}
		else
		{
			$la_date = '';
		}
		
		my ($a,$m,$j) = split(/\-/,$intranet_projet_detail{date_limite});
		my $date_limite = $j.' '.$months[$m].' '.$a;
		if($a > 0 && $m > 0 && $j >0)
		{
			$date_limite = '<span style="color:red">Date limite: '.$date_limite.'</span>';
		}
		else
		{
			$date_limite = '';
		}
		
		# style="border-right-color:#eff0f4!important;"
		
		my $from = 'alexis';
		my $to = '<span class="badge">ALEXIS</span>';
		$intranet_projet_detail{texte} =~ s/$from/$to/gi;
		
		my $from = 'freddy';
		my $to = '<span class="badge">FREDDY</span>';
		$intranet_projet_detail{texte} =~ s/$from/$to/gi;
		
		my $from = 'stef';
		my $to = '<span class="badge">STEF</span>';
		$intranet_projet_detail{texte} =~ s/$from/$to/gi;
		
		my $from = 'stephane';
		my $to = '<span class="badge">STEPHANE</span>';
		$intranet_projet_detail{texte} =~ s/$from/$to/gi;
		
		my $from = 'romain';
		my $to = '<span class="badge">ROMAIN</span>';
		$intranet_projet_detail{texte} =~ s/$from/$to/gi;
			
		my $from = 'alain';
		my $to = '<span class="badge">ALAIN</span>';
		$intranet_projet_detail{texte} =~ s/$from/$to/gi;
		
		my $from = 'greg';
		my $to = '<span class="badge">GREG</span>';
		$intranet_projet_detail{texte} =~ s/$from/$to/gi;
		
		my $from = 'loic';
		my $to = '<span class="badge">LOIC</span>';
		$intranet_projet_detail{texte} =~ s/$from/$to/gi;
		
		my $from = '\r*\n';
		my $to = '<br />';
		$intranet_projet_detail{texte} =~ s/$from/$to/gi;
		
		
		my %est_lie = (
		alain => 'btn-default',
		alexis => 'btn-default',
		freddy => 'btn-default',
		greg => 'btn-default',
		loic => 'btn-default',
		romain => 'btn-default',
		stef => 'btn-default',
		);
		
		my %initiales = (
		alain => 'AB',
		alexis => 'AM',
		freddy => 'FB',
		greg => 'GB',
		loic => 'LM',
		romain => 'RR',
		stef => 'SD',
		);
		
		my %est_type = (
		production => 'btn-default',
		financier => 'btn-default',
		suivi => 'btn-default',
		);
		
		if($intranet_projet_detail{production} eq 'y')
		{
			$est_type{production} = 'btn-primary';
		}
		if($intranet_projet_detail{financier} eq 'y')
		{
			$est_type{financier} = 'btn-primary';
		}
		if($intranet_projet_detail{suivi} eq 'y')
		{
			$est_type{suivi} = 'btn-primary';
		}	
		
		my $lies = '';
		foreach $bugi (keys %est_lie)
		{
			if($intranet_projet_detail{$bugi} eq 'y')
			{
				$est_lie{$bugi} = 'btn-primary';
				$lies .= $initiales{$bugi}.' ';
			}
		}
		my $sel_reunion = $sel_technique = 'btn-link';
		if($intranet_projet_detail{technique} eq 'y')
		{
			$sel_technique = 'btn-default';
		}
		else
		{
			$sel_reunion = 'btn-default';
		}
		
		$intranet_projet_detail{texte} =~ s/\r*\n/<br>/g;
		
		my $auteur = '';
		if($intranet_projet_detail{detail_id_user} > 0)
		{
			my %user = read_table($dbh,'users',$intranet_projet_detail{detail_id_user});
			$auteur = $user{identity};
		}		
	
		my $visible_button = <<"EOH";
         <a href="$dm_cfg{self}&sw=ajax_changevis" data-placement="bottom" data-original-title="Rendre visible/invisible"  id="$intranet_projet_detail{id}"
          role="button"
		  data-url="http://my.bugiweb.net/cgi-bin/adm_admin_intranet_projets_details.pl?&sw=ajax_changevis" 
          class="btn btn-danger  btn-mini show_only_after_document_ready link_changevis_$dm_cfg{nolabelbuttons} link_changevis link_changevis_$intranet_projet_detail{id} set_visible toggle_visible">
              <span class="fa fa-times  fa-fw"></span> 
              $label  
          </a>
EOH
     
		if($intranet_projet_detail{visible} eq 'y')
		{
			$visible_button = <<"EOH";
			<a href="http://my.bugiweb.net/cgi-bin/adm_admin_intranet_projets_details.pl?&sw=ajax_changevis" 
          data-placement="top"
		  data-url="http://my.bugiweb.net/cgi-bin/adm_admin_intranet_projets_details.pl?&sw=ajax_changevis" 
          data-original-title="Rendre visible/invisible"  
          id="$intranet_projet_detail{id}" 
          role="button" 
          class="btn btn-default    link_changevis_$dm_cfg{nolabelbuttons} link_changevis link_changevis_$intranet_projet_detail{id} "
          >
              <span class="fa fa-check  fa-fw"></span> 
              
          </a>
EOH
		}

	
		$list .= <<"EOH";
			<article class="timeline-item " >
				<div class="timeline-desk" style="width:1500px;">
					<div class="panel $pr{statut}"   >
						<div class="panel-body" id="$intranet_projet_detail{id}">
							<span class="arrow $pr{statut}-arrow" ></span>
							<span class="timeline-icon"></span>
							<h1 style="">
							
							
							$date_limite
							
							
							
							
							</h1>
							
							
							
							
							<span class="timeline-date" style="color:#7a7676"><label style="font-weight:normal;">
							<input type="checkbox" id="$intranet_projet_detail{id}" class="cb_$i cb no-margin" /> $la_date <i>$auteur</i></label></span>
</span>
							<div class="timeline-content">
							$intranet_projet_detail{texte}
							<br />
							</div>
							
							
							
							
							
							
										<nav class="navbar navbar-default $pr{statut}" style="margin-bottom:0px; border:0px;">
										  <div class="container-fluiddis">
						
										  <span class="navbar-text"><!--<label style="font-weight:normal;"><input type="checkbox" class="" /> $la_date <i>$auteur</i></label>--></span>
										  
											<!-- Collect the nav links, forms, and other content for toggling -->
											<div class="collapse navbar-collapse pull-right" id="bs-example-navbar-collapse-1">
											
												<a   rel="suivi"  class=" $est_type{suivi} btn btn-default navbar-btn ajout_type" id="$intranet_projet_detail{id}">Suivi</a>
												<a   rel="financier"  class=" $est_type{financier} btn btn-default navbar-btn ajout_type" id="$intranet_projet_detail{id}">Financier</a>
												<a    rel="production" class=" $est_type{production} btn btn-default navbar-btn ajout_type" id="$intranet_projet_detail{id}">Production</a>
												
												<a href="http://my.bugiweb.net/cgi-bin/adm_admin_intranet_projets_details.pl?&id_intranet_projet=$id_projet" target="_blank"  class="btn btn-default navbar-btn "> <i class="fa fa-cog"></i> </a>

												$visible_button

												<ul class="nav navbar-nav ">
													<li class="dropdown">
														<a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button" aria-expanded="false"><span class="lies_container">$lies</span> <span class="caret"></span></a>
														<ul class="dropdown-menu" role="menu">
															<li><a class="btn btn-block  ajout_liaison $est_lie{alain}" data-initiale="AB" rel="alain" id="$intranet_projet_detail{id}" >Alain</a></li>
															<li><a class="btn btn-block  ajout_liaison $est_lie{alexis}" data-initiale="AM" rel="alexis"  id="$intranet_projet_detail{id}" >Alexis</a></li>
															<li><a class="btn btn-block  ajout_liaison $est_lie{freddy}" data-initiale="FB" rel="freddy"  id="$intranet_projet_detail{id}" >Freddy</a></li>
															<li><a class="btn btn-block  ajout_liaison $est_lie{greg}" data-initiale="GB" rel="greg"  id="$intranet_projet_detail{id}" >Greg</a></li>
															<li><a class="btn btn-block  ajout_liaison $est_lie{loic}" data-initiale="LC" rel="loic"  id="$intranet_projet_detail{id}" >Loic</a></li>
															<li><a class="btn btn-block  ajout_liaison $est_lie{romain}" data-initiale="RR" rel="romain"  id="$intranet_projet_detail{id}" >Romain</a></li>
															<li><a class="btn btn-block  ajout_liaison $est_lie{stef}" data-initiale="SD" rel="stef"  id="$intranet_projet_detail{id}" >Stef</a></li>
														</ul>
													</li>
												</ul>
												

											</div><!-- /.navbar-collapse -->
										  </div><!-- /.container-fluid -->
										</nav>
							
							
							
							
							
							
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

sub heal_projects
{
	see();
	my @projects = sql_lines({table=>'intranet_projets',where=>"nom=''"});
	foreach $project (@projects)
	{
		my %project = %{$project};
		
		my %backup_project = read_table($dbh,"2050622_intranet_projets",$project{id});
		%backup_project = %{quoteh(\%backup_project)};
		updateh_db($dbh2,"intranet_projets",\%backup_project,'id',$backup_project{id});
	}
	exit;
}

