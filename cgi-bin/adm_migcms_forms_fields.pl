#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;
use migcrender;

my $id_form=get_quoted('id_form');
$colg = get_quoted('colg') || $config{default_colg};
my $family_name = get_obj_name($dbh,$id_form,'forms',$colg);

$dm_cfg{customtitle} = $migctrad{products_management}.' > '.$family_name.' > '.$migctrad{dataforms_fields_title};

$dm_cfg{enable_search} = 1;
$dm_cfg{enable_multipage} = 1;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 1;
$dm_cfg{trad} = 1;

$dm_cfg{table_name} = "forms_fields";
$dm_cfg{wherep_ordby} = $dm_cfg{wherep} = "id_form=$id_form";

$dm_cfg{list_table_name} = "$dm_cfg{table_name}";

$dm_cfg{wherel} = "id_form=$id_form";

my $self=$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_forms_fields.pl?id_form=$id_form";
$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{after_add_ref} = \&after_save;
$dm_cfg{duplicate}='y';
$dm_cfg{page_title} = "Champs du formulaire";
$dm_cfg{txtsrc} = 'forms';

%field_type = (
			"textarea"=>"Texte multilignes",
			"text"=>"Texte",
			"text_email"=>"Texte email",
			"text_email_confirmation"=>"Texte confirmation de l'email",
			"text_password"=>"Texte mot de passe",
			"text_password_confirmation"=>"Texte confirmation du mot de passe",
			"checkbox"=>"Case à cocher",
			"radio"=>"Radio",
			"listbox"=>"Liste déroulante",
			"listbox_categories"=>"Liste déroulante catégories d'annuaire",
			"file"=>"Fichier",
      "handmade"=>"Champ sur-mesure",
		);
    
%etapes = (
			"1"=>"1",
			"2"=>"2",
			"3"=>"3",
			"4"=>"4",
			"5"=>"5"
		);

@dm_nav =
(
  {
      'tab'=>'integration',
      'type'=>'tab',
      'title'=>'Intégration',
  }
  ,
   {
      'tab'=>'annuaire',
      'type'=>'tab',
      'title'=>'Liaison à un annuaire',
  } 
  ,
);    

$config{logfile} = "trace.log";
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd

my %hash_data_fields = ();
my %hash_families = ();

my @data_families = sql_lines({table=>"data_families"});
foreach $data_family (@data_families)
{
  my %data_family = %{$data_family};
  $hash_families{$data_family{id}} = $data_family{name};
}

# On boucle sur les champs data_fields
my @data_fields = sql_lines({table=>"data_fields"});
foreach $data_field (@data_fields)
{
  my %data_field = %{$data_field};

  my $field_name = get_traduction({id=>$data_field{id_textid_name}});

  if($hash_families{$data_field{id_data_family}} ne "")
  {
    $hash_data_fields{$data_field{id}} = $hash_families{$data_field{id_data_family}} . " - " . $field_name;    
  }
}

 

%dm_dfl = (
  '00/id_form' =>
  {
    'title'=> 'form',
    'fieldtype'=> 'text',
    'search' => 'n',
    'tab' => 'tab_fiche',
    'hidden' => 1,
    'tab' => 'integration',
  },
	    '01/id_textid_name'=> {
	        'title'=>$migctrad{id_textid_name},
	        'fieldtype'=>'text_id',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty'},
          'tab' => 'integration',
	    }
      ,
      '02/code'=> 
      {
      'title'=>'Identifiant du champ',
      'fieldtype'=>'text',
      'fieldsize'=>'50',
      'inline_edit' =>'y',
      'tab' => 'integration',
	    }
       ,
	    '03/step'=> {
	        'title'=>'Etape',
	        'fieldtype'=>'listbox',
	        'fieldvalues'=>\%etapes,
          'tab' => 'integration',
	        }
	    ,
	    '04/type'=> {
	        'title'=>$migctrad{field_type},
	        'fieldtype'=>'listbox',
	        'fieldvalues'=>\%field_type,
          'tab' => 'integration',
	        }
          ,
          '05/id_data_category_father' => 
      {
           'title'=>'Catégories à afficher (Liste déroulante catégories)',
           'fieldtype'=>'listboxtable',
       'datatype'=>'treeview',
           'lbtable'=>'data_categories',
           'lbkey'=>'id',
           'lbdisplay'=>'id_textid_name',
           'translate'=>1,
           'multiple'=>0,
        'tree_col'=>'id_father',
        'summary'=>0,
           'lbwhere'=>"",
           'tab' => 'integration',
      }
    ,
     '06/handmade_field_func'=> 
      {
      'title'=>'Fonction pour renvoyer la valeur du champ (Champ sur-mesure)',
      'fieldtype'=>'text',
      'fieldsize'=>'50',
      'inline_edit' =>'y',
      'tab' => 'integration',
      },
	    '08/mandatory'=> 
          {
	        'title'=>$migctrad{mandatory},
	        'fieldtype'=>'checkbox',
	        'checkedval' => 'y',
          'tab' => 'integration',
	        },
          
          ,
	    '90/id_pic'=> 
      {
	        'title'=>"Photo",
	        'fieldtype'=>'pic',
	        'fieldpath' => $config{root_path}.'/pics/',
          'tab' => 'integration',
	    }
	     ,   
      '10/nbchar_min'=> {
      'title'=>$migctrad{dataform_nb_char},
      'fieldtype'=>'text',
      'fieldsize'=>'50',
      'tab' => 'integration',
	    }
	    
	    ,
	    '11/nbchar_max'=> {
      'title'=>$migctrad{dataform_nb_char_max},
      'fieldtype'=>'text',
      'fieldsize'=>'50',
      'tab' => 'integration',
	    }
	    
	    	   
	    
	    ,
	    '15/in_list'=> {
      'title'=>'Ds la liste',
      'fieldtype'=>'checkbox',
	     'checkedval' => 'y',
       'tab' => 'integration',
	     },

       '20/id_data_field'=> 
      {
      'title'=>"Champs de l'annuaire lié",
      'fieldtype'=>'listbox',
      'fieldvalues'=>\%hash_data_fields,
      'tab' => 'annuaire',
      }  
      ,
      '24/sheet_pic'=> {
        'title'=>'Photo d\'une sheet',
        'fieldtype'=>'checkbox',
        'checkedval' => 'y',
        'tab' => 'annuaire',
      },
      '25/sheet_category'=> {
        'title'=>'Catégorie d\'une sheet',
        'fieldtype'=>'checkbox',
        'checkedval' => 'y',
        'tab' => 'annuaire',
      },
	     
	  
 
	);




%dm_display_fields = (
	"02/$migctrad{id_textid_name}"=>"id_textid_name",
  "01/Etape"=>"step",
  "20/Type"=>"type",
	"05/Obligatoire ?"=>"mandatory",
  "14/Listing ?"=>"in_list",
  "19/Identifiant"=>"code",
		);

%dm_lnk_fields = (

"23/$migctrad{valeurs}"=>"ftv*",

		);

%dm_mapping_list = (
"ftv" => \&get_field_type_values
);

%dm_filters = (
		);

$dm_cfg{help_url} = "http://www.bugiweb.com";

# this script's name

$sw = $cgi->param('sw') || "list";
my $selfcolg=$self.'&sw='.$sw.'&id='.get_quoted('id');       

$dm_cfg{hiddp}=<<"EOH";
<input type="hidden" name="colg" value="$colg" />
<input type="hidden" value="$id_form" name="id_form" />
EOH

see();

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
    dm_init();
    
    
    if($sw eq "ordby")
    {
      &$sw();
    }
    else
    {
      &$sw();
    }
    
    $spec_bar = get_spec_buttonbar($sw);
#     print wfw_app_layout($dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
    $migc_output{content} .= $dm_output{content};
    $migc_output{title} = $dm_output{title}.$migc_output{title};
    
    print migc_app_layout($migc_output{content},$migc_output{title},"",$gen_bar,$spec_bar);
}
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub get_and_check
{
	my %item; 
  my $op = $_[0];
  
	foreach $key (keys(%dm_dfl))
	{ 
		my ($num,$field) = split(/\//,$key);
		
		$item{$field} = get_quoted($field);
#     print "<br /><code>[$field](".$dm_dfl{$key}{fieldtype}.")</code>";
		 if (($dm_dfl{$key}{fieldtype} eq "text_id") || ($dm_dfl{$key}{fieldtype} eq "textarea_id"))
      {
#       print "->TXTID:[$field]";           
       %item = %{update_textid_field($dbh,$field,$op,\%item)};
      }
      elsif ($dm_dfl{$key}{fieldtype} eq "pic")
      { 
           %item = %{update_pic_field_admin_fixed($dbh,$field,$op,\%item,$datadir_config{upload_path},$config{dataform_small},$config{dataform_small},$config{dataform_medium},$config{dataform_medium},$config{dataform_mini},$config{dataform_mini},"")};
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

 my $del_id_pic = get_quoted('del_id_pic') || 'n';
 if($del_id_pic eq 'y')
 {
    $item{id_pic} = 0;
 } 

 $item{id_form} = $id_form;
 
 # exit;
	return (\%item);	
}


sub get_field_type_values
{
    my $dbh = $_[0];
    my $id = $_[1];

    my $sel = get_quoted("sel");
 
    my $stmt;
    $stmt="select * from forms_fields where id='".$id."'";
  	my $cursor = $dbh->prepare($stmt);
  	my $rc = $cursor->execute;
  	if (!defined $rc) 
  	{
  	  see();
  	  print "[$stmt]";
  	  exit;   
  	}	
  	
  	while ($ref_rec = $cursor->fetchrow_hashref()) 
  	{
  	  my %rec = %{$ref_rec};
  		if($rec{type} eq "listbox" || $rec{type} eq "radio" || $rec{type} eq "listbox_tree")
  		{
        return <<"EOH";
        <a class="btn btn-default" href="$config{baseurl}/cgi-bin/adm_migcms_forms_field_listvalues.pl?id_field=$id&id_form=$rec{id_form}&type=$rec{type}&sel=$sel" title="$migctrad{valeurs}">Valeurs</a>
EOH
      }
  	} 
  	return '';
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

sub after_save
{
  my $dbh = $_[0];
  my $id = $_[1];
  
  my %field=read_table($dbh,"forms_fields",$id);
  if($field{code} eq '')
  {
      my $code = sprintf("%02d",$field{ordby});
      $stmt = "UPDATE forms_fields SET code = '$code' WHERE id='$id'";
      execstmt($dbh,$stmt);
  }
  if(!($field{step} > 0))
  {
      $stmt = "UPDATE forms_fields SET step = 1 WHERE id='$id'";
      execstmt($dbh,$stmt);
  }
}



sub change_ordby
{
 my $id = get_quoted('id');
 my $old = get_quoted('old');
 my $new = get_quoted('new');
 my $op = get_quoted('op');
 my $ordbymax = 0;
 
 my ($stmt,$cursor);
 
 $wherep = $dm_cfg{wherep_ordby} || "";
 
 if ($wherep ne "") { $wherep = "AND ".$wherep;}
 
 if ($op eq "bottom" || $op eq "down" || $op eq "goto") {
     $stmt = "SELECT MAX(ordby) FROM $dm_cfg{table_name} WHERE 1=1 $wherep";
#     print $stmt;
#     exit;
     $cursor = $dbh->prepare($stmt);
     $cursor->execute || wfw_exception("SQL_ERROR","error execute : $DBI::errstr [$stmt]\n");
     ($ordbymax) = $cursor->fetchrow_array;
     $cursor->finish;
    
     if ($op eq "bottom") {$new = $ordbymax;}
     elsif ($op eq "down") {$new = $old + 1;}

    if (!($new =~ /[0-9]/)) {
        make_error($fwtrad{dm_ordbymax_error_notnumber});
    }

     if ($new > $ordbymax) {
        make_error($fwtrad{dm_ordbymax_error});
    }
    
 } elsif ($op eq "top") {
       $new = 1;
 }
   elsif ($op eq "up") {
       $new = $old - 1; 
 }

 if ($new < 1) { $new = 1;} 
 
 $stmt = "UPDATE $dm_cfg{table_name} SET ordby = ordby-1 WHERE ordby>$old $wherep";
 execstmt($dbh,$stmt);

 $stmt = "UPDATE $dm_cfg{table_name} SET ordby = ordby+1 WHERE ordby>=$new $wherep";
 execstmt($dbh,$stmt);

 $stmt = "UPDATE $dm_cfg{table_name} SET ordby = $new WHERE id = $id";
 execstmt($dbh,$stmt);
 
 if ($new < $old) {
     $lowlim = $new;
     $highlim = $old;
     $way = "down";
 } else {
     $lowlim = $old;
     $highlim = $new;
     $way = "up";
 
 }
# use Data::Dumper;
 
# see();
 $stmt = "SELECT * FROM forms_data where id = $id";
 
 my $cursor = $dbh->prepare($stmt);
 $cursor->execute || die("error execute : $DBI::errstr [$stmt]\n");
 while($ref = $cursor->fetchrow_hashref()) {
     my %row = %{$ref};

#    print "<br /><pre>".Dumper(\%row)."</pre>";

     if ($way eq "down") {
         for ($i=$lowlim; $i<$highlim; $i++) {
             $tmp = $row{"f".$i};
             $row{"f".$i} = $row{"f".($i+1)};
             $row{"f".($i+1)} = $tmp;
             print "<br />f".($i+1)." <= f $i";
         }
     }
     elsif ($way eq "up") {
         for ($i=$highlim; $i>$lowlim; $i--) {
             $tmp = $row{"f".$i};
             $row{"f".$i} = $row{"f".($i-1)};
             $row{"f".($i-1)} = $tmp;
             print "<br />f".($i-1)." <= f $i";
         }
     }
     
     

#     if (($new < $old) && op eq "top" ) {
#         $row{"f".$lowlim} = $row{"f".$highlim};
#     }

#    print "<br /><pre>".Dumper(\%row)."</pre>";
#     exit;

     foreach $f (keys %row) { $row{$f} =~ s/\'/\\\'/g; }

     
     updateh_db($dbh,"forms_data",\%row,"id",$row{id});
 }
 $cursor->finish;


 
 http_redirect("$dm_cfg{self_mp}"); 
}

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------