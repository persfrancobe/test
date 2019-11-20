#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;

use fwlayout;
use fwlib;
use Data::Dumper;
# migc modules

         # migc translations


use migccms;
use migcrender;
use Spreadsheet::ParseExcel;
use Spreadsheet::WriteExcel;

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###############################################################################################
####################################	CODE DU PROGRAMME		######################################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

my %user = %{get_user_info($dbh, $config{current_user})} or wfw_no_access();
$colg = get_quoted('colg') || $config{default_colg};



my $id_form= get_quoted('id_form');


$dm_cfg{customtitle} = $migctrad{products_management}.' > '.$migctrad{product_families_list};
$dm_cfg{enable_search} = 1;
$dm_cfg{add} = 0;
$dm_cfg{edit} = 1;
$dm_cfg{enable_multipage} = 1;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{wherel} = "id_form = $id_form";
$dm_cfg{wherep} = "id_form = $id_form";
$dm_cfg{table_name} = "forms_data";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{get_form_ref} = \&get_form;
$dm_cfg{get_view_ref} = \&get_view;
$dm_cfg{get_and_check_ref} = \&get_and_check;
$dm_cfg{before_del_ref} = \&before_del;
$dm_cfg{table_width} = 850;
$dm_cfg{fieldset_width} = 850;
my $self=$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_forms_data.pl?id_form=$id_form";

$dm_cfg{after_mod_ref} = \&up;
$dm_cfg{default_ordby} = "id desc";
$dm_cfg{after_add_ref} = \&up;

$config{logfile} = "trace.log";

$dm_cfg{page_title} = "Données récoltées";



#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = ();
%dm_display_fields = ();


if($id_form > 0)
{
}
else
{
    my $id=get_quoted('id');
    my %forms_data = read_table($dbh,'forms_data',$id); 
    $id_form = $forms_data{id_form};
}

my @fields = sql_lines({debug=>0,debug_results=>0,table=>'forms_fields',where=>"id_form = $id_form",ordby=>'ordby'});
foreach $field (@fields)
{
   my %field = %{$field};
   my $ordby = sprintf("%02d",$field{ordby});
   my ($name,$dum) = get_textcontent($dbh,$field{id_textid_name});
   $dm_dfl{$ordby.'/f'.$field{ordby}}{title}=$name;
   $dm_dfl{$ordby.'/f'.$field{ordby}}{search}='y';
#    if($field{type} eq 'text')
#    {
#        
#    }
#    elsif($field{type} eq 'radio' || $field{type} eq 'listbox'  || $field{type} eq 'checlbox' )
#    {
#        $dm_dfl{$ordby.'/f'.$field{ordby}}{fieldtype}='listboxtable';
#        $dm_dfl{$ordby.'/f'.$field{ordby}}{lbtable}='forms_fields_listvalues f, textcontents txt';
#        $dm_dfl{$ordby.'/f'.$field{ordby}}{lbkey}='f.id';
#        $dm_dfl{$ordby.'/f'.$field{ordby}}{lbdisplay}='content';
#        $dm_dfl{$ordby.'/f'.$field{ordby}}{lbwhere}="id_field = '$field{id}' AND f.id_textid_name = txt.id_textid AND id_language = 1 ";
#    }
   
   if($field{type} eq 'file')
   {
      $dm_dfl{$ordby.'/f'.$field{ordby}}{fieldtype}='display'; 
   }  
   else
   {
      $dm_dfl{$ordby.'/f'.$field{ordby}}{fieldtype}='text';
   }
   
   if($field{in_list} eq 'y')
   {
      $dm_display_fields{"$ordby/$name"}='f'.$field{ordby};
   }
}





# see(\%dm_dfl);
# see(\%dm_display_fields);

%dm_lnk_fields = (
		);

%dm_mapping_list = (
);

%dm_filters = (
		);

$dm_cfg{help_url} = "http://www.bugiweb.com";


# this script's name

$sw = $cgi->param('sw') || "list";
my $selfcolg=$self.'&sw='.$sw.'&id='.get_quoted('id');       
my $colg_menu = get_colg_menu($dbh,$colg,$selfcolg);

$dm_cfg{hiddp}=<<"EOH";
<input type="hidden" name="colg" value="$colg" />
<input type="hidden" value="$id_form" name="id_form" />
EOH

if($sw ne 'get_content_xls')
{
see();
}
my @fcts = qw(
			add_form
			mod_form
			list
			add_db
			mod_db
			del_db
			up
		);

if (is_in(@fcts,$sw)) 
{ 
    dm_init();
    &$sw();
    $gen_bar = get_migc_gen_buttonbar("$colg_menu ");
    $spec_bar = get_spec_buttonbar($sw);
    $migc_output{content} .= $dm_output{content};
    $migc_output{title} = $dm_output{title}.$migc_output{title};
    my $js = <<"EOH";
  <script>
  jQuery(document).ready(function() 
  {
       jQuery('.mig_txt').each(function(i)
       {
          var content = jQuery(this).html();
          jQuery(this).html('<a target="_blank" href="usr/'+content+'">'+content+'</a>');
       
       
       });
  }); 
  </script>
EOH
    print migc_app_layout($js.$migc_output{content},$migc_output{title},"",$gen_bar,$spec_bar);;
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

		 if ($dm_dfl{$key}{fieldtype} eq "text_id" || $dm_dfl{$key}{fieldtype} eq "textarea_id")
      {           
       %item = %{update_textid_field($dbh,$field,$op,\%item)};
      }
      elsif ($dm_dfl{$key}{fieldtype} eq "file")
      { 
             
             if($datadir_config{upload_path} eq "")
             {
                $datadir_config{upload_path}=$config{root_path}.'/usr/';
             }
             
             
             
             %item = %{update_file_field_admin($dbh,$field,$op,\%item,$datadir_config{upload_path})};

            
             
             if ($item{$field} eq "") {delete $item{$field};} elsif ($item{$field} eq " "){$item{$field}="";} 
      }
      elsif ($dm_dfl{$key}{fieldtype} eq "pic")
      { 
           %item = %{update_pic_field_admin($dbh,$field,$op,\%item,$datadir_config{upload_path})};
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
  
  #$item{id_dataform}=$id_dataform;

  if(!($item{id_form} > 0))
  {
    $item{id_form} = get_quoted('id_form');  
  }
 
	return (\%item);	
}

sub up
{
    my $dbh=$_[0];
    my $id=$_[1];
   
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

sub get_content_xls
{
 my $id_form= get_quoted('id_form') || 1;
  
 my $stmt = "SELECT type,ordby,id_textid_name 
               FROM forms_fields 
              WHERE id_form = $id_form
              ORDER BY ordby";
              
 my $cursor = $dbh->prepare($stmt);
 my $rc = $cursor->execute;
 
 my ($type,$col,$file,$pic);

 my @fields,@header,@data,@row;
 
 $cursor->bind_columns(\$type,\$col,\$id_name);
 
 while ($cursor->fetch())
  {
   if ($type ne "file" && $type ne "pic") {push @fields,"f".$col;}
   my ($name,$dum) = get_textcontent($dbh,$id_name,$config{current_language});
   push @header,$name;
   $fieldtypes{"f".$col} = $type;
  }
 $cursor->finish();

 my $fields = join(',',@fields);

# print $cgi->header(-expires=>'-1d');

 if ($fields ne "")
     {
      $stmt = "SELECT $fields FROM forms_data WHERE id_form = $id_form ORDER BY id ";
      $cursor = $dbh->prepare($stmt);
      $rc = $cursor->execute;
      while (%row = %{$cursor->fetchrow_hashref()})
       {
        @row = ();
        foreach $key (@fields) {
            if ($fieldtypes{$key} eq "listbox") {
                $rowcol = $row{$key};
                $rowcol =~ s/\'/\\\'/g;
                push @row, get_obj_name($dbh,$rowcol,"forms_fields_listvalues");
            } else {
                push @row, from_utf8({ -string => $row{$key}, -charset => 'ISO-8859-1' });
            }
        }
        my @myrow = @row;
        push @data, (\@myrow);       
       }
       
     }

#use Spreadsheet::SimpleExcel;

# binmode(\*STDOUT);

#  # create a new instance
#  my $excel = Spreadsheet::SimpleExcel->new();

#  # add worksheets
#  $excel->add_worksheet('Dataform',{-headers => \@header, -data => \@data});

#  # print into file
#  $outfile = $config{pic_dir}."/tmpxls.xls";
#  $excel->output_to_file($outfile);

#print $cgi->redirect(-location=>$outfile,-content-type=>'application/vnd.ms-excel');


#print $cgi->header(-location=>$outfile,-content-type=>'application/vnd.ms-excel');

use Spreadsheet::WriteExcel;

 binmode(\*STDOUT);

  $outfile = $config{pic_dir}."/".create_token(10).".xls";

print "Content-type: application/vnd.ms-excel\n";
    print "Content-Disposition: attachment; filename=$outfile\n";
    print "\n";


  # create a new instance
  my $excel = Spreadsheet::WriteExcel->new(\*STDOUT);

  # add worksheets
  my $ws = $excel->add_worksheet('Dataform');
  $ws->add_write_handler(qr[\w], \&store_string_widths);
  my $c = 0;
  my $l = 0;

  for ($c = 0; $c <= $#header; $c++) {
       $ws->write($l,$c,$header[$c]);
  }


 for (my $l = 0; $l <=$#data; $l++) {
      my @t = @{$data[$l]};
     for ($c = 0; $c <= $#t; $c++) {
       $ws->write($l+1,$c,$t[$c]);
     }
 }
autofit_columns($ws);
$excel->close();



}
###############################################################################
#
# Functions used for Autofit.
#
###############################################################################

###############################################################################
#
# Adjust the column widths to fit the longest string in the column.
#
sub autofit_columns {

    my $worksheet = shift;
    my $col       = 0;

    for my $width (@{$worksheet->{__col_widths}}) {

        $worksheet->set_column($col, $col, $width) if $width;
        $col++;
    }
}


###############################################################################
#
# The following function is a callback that was added via add_write_handler()
# above. It modifies the write() function so that it stores the maximum
# unwrapped width of a string in a column.
#
sub store_string_widths {

    my $worksheet = shift;
    my $col       = $_[1];
    my $token     = $_[2];

    # Ignore some tokens that we aren't interested in.
    return if not defined $token;       # Ignore undefs.
    return if $token eq '';             # Ignore blank cells.
    return if ref $token eq 'ARRAY';    # Ignore array refs.
    return if $token =~ /^=/;           # Ignore formula

    # Ignore numbers
    return if $token =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/;

    # Ignore various internal and external hyperlinks. In a real scenario
    # you may wish to track the length of the optional strings used with
    # urls.
    return if $token =~ m{^[fh]tt?ps?://};
    return if $token =~ m{^mailto:};
    return if $token =~ m{^(?:in|ex)ternal:};


    # We store the string width as data in the Worksheet object. We use
    # a double underscore key name to avoid conflicts with future names.
    #
    my $old_width    = $worksheet->{__col_widths}->[$col];
    my $string_width = string_width($token);

    if (not defined $old_width or $string_width > $old_width) {
        # You may wish to set a minimum column width as follows.
        #return undef if $string_width < 10;

        $worksheet->{__col_widths}->[$col] = $string_width;
    }


    # Return control to write();
    return undef;
}


###############################################################################
#
# Very simple conversion between string length and string width for Arial 10.
# See below for a more sophisticated method.
#
sub string_width {

    return 0.9 * length $_[0];
}

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------