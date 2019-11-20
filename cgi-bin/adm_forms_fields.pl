#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;
# migc modules

         # migc translations


use migcrender;
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###############################################################################################
####################################	CODE DU PROGRAMME		######################################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

my %user = %{get_user_info($dbh, $config{current_user})} or wfw_no_access();
my $id_form=get_quoted('id_form');

$colg = get_quoted('colg') || $config{default_colg};



my $family_name = get_obj_name($dbh,$id_form,'forms',$colg);

$dm_cfg{customtitle} = $migctrad{products_management}.' > '.$family_name.' > '.$migctrad{dataforms_fields_title};

$dm_cfg{enable_search} = 1;
$dm_cfg{enable_multipage} = 1;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 1;



$dm_cfg{table_name} = "forms_fields";
$dm_cfg{wherep_ordby} = $dm_cfg{wherep} = "id_form=$id_form";

$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
#$dm_cfg{list_table_name} = "$dm_cfg{table_name},textcontents AS txt, textcontents AS txt2, textcontents AS txt3";

$dm_cfg{wherel} = "id_form=$id_form";
$dm_cfg{get_form_ref} = \&get_form;
$dm_cfg{get_view_ref} = \&get_view;
$dm_cfg{get_and_check_ref} = \&get_and_check;
$dm_cfg{before_del_ref} = \&before_del;
$dm_cfg{table_width} = 850;
$dm_cfg{fieldset_width} = 850;
my $self=$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_forms_fields.pl?id_form=$id_form";
$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{after_add_ref} = \&after_save;
$dm_cfg{duplicate}='y';

$dm_cfg{page_title} = 'Champs du formulaire';
$dm_cfg{add_title} = "Ajouter un champs";

#"file"=>"$migctrad{file}"
#"listbox"=>"$migctrad{listbox}",

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
			"listbox_tree"=>"Liste déroulante arborescente",
			"file"=>"Fichier"
		);
    
%etapes = (
			"1"=>"1",
			"2"=>"2",
			"3"=>"3",
			"4"=>"4",
			"5"=>"5"
		);    

$config{logfile} = "trace.log";
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (
	    '01/id_textid_name'=> {
	        'title'=>$migctrad{id_textid_name},
	        'fieldtype'=>'text_id',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty'},
	    }
      ,
      '02/code'=> 
      {
      'title'=>'Identifiant du champ',
      'fieldtype'=>'text',
      'fieldsize'=>'50'
	    }
       ,
	    '03/step'=> {
	        'title'=>'Etape',
	        'fieldtype'=>'listbox',
	        'fieldvalues'=>\%etapes
	        }
	    ,
	    '04/type'=> {
	        'title'=>$migctrad{field_type},
	        'fieldtype'=>'listbox',
	        'fieldvalues'=>\%field_type
	        }
          ,
	    '05/mandatory'=> 
          {
	        'title'=>$migctrad{mandatory},
	        'fieldtype'=>'checkbox',
	        'checkedval' => 'y'
	        },
          
          ,
	    '90/id_pic'=> 
      {
	        'title'=>"Photo",
	        'fieldtype'=>'pic',
	        'fieldpath' => $config{root_path}.'/pics/'
	    }
	     ,   
      '06/nbchar_min'=> {
      'title'=>$migctrad{dataform_nb_char},
      'fieldtype'=>'text',
      'fieldsize'=>'50'
	    }
	    
	    ,
	    '10/nbchar_max'=> {
      'title'=>$migctrad{dataform_nb_char_max},
      'fieldtype'=>'text',
      'fieldsize'=>'50'
	    }
	    
	    	   
	    
	    ,
	    '12/in_list'=> {
      'title'=>'Ds la liste',
      'fieldtype'=>'checkbox',
	     'checkedval' => 'y'
	     }
	      ,
      '99/id_data_field'=> 
      {
      'title'=>"Champs de l'annuaire lié",
      'fieldtype'=>'listboxtable',
      'lbtable'=>'data_fields',
      'lbkey'=>'data_fields.id',
      'lbdisplay'=>"CONCAT('FAMILLE',id_data_family,', f',data_fields.ordby)",
      'lbwhere'=>"",
      }  
	     
		 ,
      '98/id_form'=> 
      {
      'title'=>"ID formulaire",
      'fieldtype'=>'text',
      'hidden'=>1,      
      }  
 
	);
# 	       '13/id_textid_msg'=> {
# 	        'title'=>$migctrad{dataform_errormsg},
# 	        'fieldtype'=>'textarea_id',
# 	        'fieldparams'=>'cols=47 rows=5'
# 	    }
# 	    ,
# 	   '14/id_textid_infobulle'=> {
# 	        'title'=>$migctrad{dataform_infobulle},
# 	        'fieldtype'=>'textarea_id',
# 	        'fieldparams'=>'cols=47  rows=5'
# 	    }
#    ,
# 	    '11/ext'=> {
#       'title'=>'Extensions autorisées (vide = toutes)',
#       'fieldtype'=>'text',
#       'fieldsize'=>'50'
# 	    }


%dm_display_fields = (
	"01/$migctrad{id_textid_name}"=>"id_textid_name",
  "02/Etape"=>"step",
#	"02/$migctrad{field_type}"=>"type",
	"05/$migctrad{mandatory}"=>"mandatory",
  "14/Ds la liste"=>"in_list",
  "03/Identifiant"=>"code",
#	"04/$migctrad{dataform_nb_char}"=>"nbchar_min",
#	"05/$migctrad{dataform_nb_char_max}"=>"nbchar_max"
		);

%dm_lnk_fields = (
"04/$migctrad{field_type}"=>"ft*",
"23/$migctrad{valeurs}"=>"ftv*",

		);

%dm_mapping_list = (
"ft" => \&get_field_type,
"ftv" => \&get_field_type_values
);

%dm_filters = (
		);

$dm_cfg{help_url} = "http://www.bugiweb.com";

# this script's name

$sw = $cgi->param('sw') || "list";
my $selfcolg=$self.'&sw='.$sw.'&id='.get_quoted('id');       

$dm_cfg{hiddp}=<<"EOH";
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


sub get_field_type_values
{
    my $dbh = $_[0];
    my $id = $_[1];
 
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
        <a href="$config{baseurl}/cgi-bin/adm_forms_field_listvalues.pl?id_field=$id&id_form=$rec{id_form}&type=$rec{type}" title="$migctrad{valeurs}">$migcicons{edit}</a>
EOH
      }
  	} 
  	return '';
}



sub get_field_type
{
    my $dbh = $_[0];
    my $id = $_[1];

    my $stmt;
    $stmt="select type from forms_fields where id='".$id."'";
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
  		return "$field_type{$rec{type}}";
  	}
  	return 'not found';
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