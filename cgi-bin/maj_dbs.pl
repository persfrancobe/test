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
use Data::Dumper;
# migc modules
#
#         # migc translations
#
#
use Spreadsheet::ParseExcel;
use Spreadsheet::WriteExcel;
use sitetxt;
use eshop;

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###############################################################################################
####################################	CODE DU PROGRAMME		######################################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------






# my %user = %{get_user_info($dbh, $config{current_user})} or wfw_no_access();
my $htaccess_ssl = $config{rewrite_ssl};
my $htaccess_protocol_rewrite = "http";
if($htaccess_ssl eq 'y') {
  $htaccess_protocol_rewrite = "https";
}

$dm_cfg{customtitle}=<<"EOH";
EOH

$dm_cfg{enable_search} = 0;
$dm_cfg{enable_multipage} = 0;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{wherel} = "";
$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "migcms_setup";
$dm_cfg{list_table_name} = "migcms_setup";
$dm_cfg{get_form_ref} = \&get_form;
$dm_cfg{get_view_ref} = \&get_view;
$dm_cfg{get_and_check_ref} = \&get_and_check;
# $dm_cfg{before_del_ref} = \&before_del;
$dm_cfg{table_width} = 850;
$dm_cfg{fieldset_width} = 850;
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_setup_migcms.pl?";

$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{after_add_ref} = \&after_save;
$dm_cfg{after_ordby_ref} = '';
$config{logfile} = "trace.log";
$dm_cfg{hiddp}=<<"EOH";
EOH

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = 
(
      '10/view_edit_on'=> 
      {
      'title'=>'Activer retouches rapides',
      'fieldtype'=>'checkbox',
      'checkedval' => 'y'
      }
      ,
      '20/id_default_page'=> 
      {
      'title'=>'Première page',
       'fieldtype'=>'listboxtable',
      'lbtable'=>'migcms_pages c, txtcontents txt',
      'lbkey'=>'c.id',
      'lbdisplay'=>'lg1',
      'lbwhere'=>"visible = 'y' and migcms_pages_type='page' and txt.id=id_textid_name",
      'mandatory'=>{"type" => 'not_empty'}
      }
	  ,
      '21/id_404_page'=> 
      {
      'title'=>'Page 404',
       'fieldtype'=>'listboxtable',
      'lbtable'=>'migcms_pages c, txtcontents txt',
      'lbkey'=>'c.id',
      'lbdisplay'=>'lg1',
      'lbwhere'=>"visible = 'y' and migcms_pages_type='page' and txt.id=id_textid_name",
      'mandatory'=>{"type" => 'not_empty'}
      }
      ,
      '30/admin_first_page_url'=> 
      {
      'title'=>"Première page de l'admin",
      'fieldtype'=>'text',
      }
      
);


%dm_display_fields = (
"01/Première page de l'admin"=>"admin_first_page_url"
		);

%dm_lnk_fields = (
		);

%dm_mapping_list = (
);

%dm_filters = (
		);
		
	

$dm_cfg{help_url} = "http://www.bugiweb.com";
# this script's name

$sw = $cgi->param('sw') || "update_dbs";

see();

my @fcts = qw(
			add_form
			mod_form
			list
			add_db
			mod_db
			del_db
			update_dbs
		);

if (is_in(@fcts,$sw)) 
{ 
    # dm_init();
    &$sw();
	exit;
    $gen_bar = get_gen_buttonbar();
    $spec_bar = get_spec_buttonbar($sw);
    
    
    
    
    my $suppl_js=<<"EOH";
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <script type="text/javascript">
    jQuery(document).ready(function() 
    {
    });
    </script>
EOH

    if($sw ne "dum")
    {
      $migc_output{content} .= $dm_output{content};
      $migc_output{title} = $dm_output{title}.$migc_output{title};
      print migc_app_layout($suppl_js.$dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
    }
}

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub get_and_check
{
	my %item; 
  my $op = $_[0];
 
  my $id_banner_zone = get_quoted('id_banner_zone');
  my %banner_zone = read_table($dbh,"banners_zones",$id_banner_zone);
  
  my $upload_path = $config{root_path}.'/usr/';
  
	foreach $key (keys(%dm_dfl))
	{ 
		my ($num,$field) = split(/\//,$key);
		
		$item{$field} = get_quoted($field);

		 if ($dm_dfl{$key}{fieldtype} eq "text_id" || 
         $dm_dfl{$key}{fieldtype} eq "textarea_id" || $dm_dfl{$key}{fieldtype} eq "textarea_id_editor")
      {        
       %item = %{update_textid_field($dbh,$field,$op,\%item)};
      }
      elsif ($dm_dfl{$key}{fieldtype} eq "file")
      { 
             
             $item{$field} = $cgi->param($field);
             
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
           %item = %{update_pic_field_admin_fixed($dbh,$field,$op,\%item,$upload_path,$banner_zone{height},$banner_zone{width},$banner_zone{width},$banner_zone{height},$banner_zone{width},$banner_zone{height},"fixed_height","")};
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


sub after_save
{
    my $dbh=$_[0];
    my $id_banner =$_[1];
    

}

sub update_dbs
{
    
    my %conv_types =
    (
          'int' => 'int',
          'date' => 'date',
		  'time' => 'time',
          'varchar' => 'varchar',
          'datetime' => 'datetime',
          'bigint' => 'int',
          'float' => 'float',
          'timestamp' => 'datetime',
          'char' => 'varchar',
          'text' => 'text',
          'smallint' => 'int',
          'enum' => 'enum_y_n',  
     );
        
     my $msg= '<h1>Mise à niveau de la base de données</h1>';   
             
    #CREATION AUTO DES TABLES MANQUANTES 
    my @list_of_tables_demozone = get_list_of_tables('demozonev4');
    my @list_of_tables_site = get_list_of_tables($config{projectname});
        
    foreach my $table_demozone (@list_of_tables_demozone)
    {
         if($table_demozone ne '')
         {
             my $existe = 0;
             foreach my $table_site (@list_of_tables_site)
             {
                  if($table_demozone eq $table_site)
                  {
                     $existe = 1;
                  }
             } 
             if($existe == 0)
             {
                 #creer la table qui n'existe pas.
                 $msg .= '<hr />Ajout de la table <b>'.$table_demozone.'</b>';
                 my $stmt = <<"EOH";
                 CREATE TABLE IF NOT EXISTS `$table_demozone` (
                    `id` int(11) NOT NULL AUTO_INCREMENT,
                    PRIMARY KEY (`id`)
                  ) ENGINE=MyISAM DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;
EOH
                  execstmt($dbh,$stmt);
             }
         }   
    }
    
    #CREATION AUTO DES CHAMPS MANQUANTS 
    my @list_of_tables_demozone = get_list_of_tables('demozonev4');
    my @list_of_tables_site = get_list_of_tables($config{projectname});    
    my %cas = ();
    foreach my $table (@list_of_tables_demozone)
    {    
        my @list_of_cols_demozone = get_list_of_cols('demozonev4',$table);
        my @list_of_cols_site = get_list_of_cols($config{projectname},$table);   
               
        foreach my $col_demozone (@list_of_cols_demozone)
        {
            my %col_demozone = %{$col_demozone};
            my $existe = 0;
            foreach my $col_site (@list_of_cols_site)
            {
                my %col_site = %{$col_site}; 
                if($col_demozone{COLUMN_NAME} eq $col_site{COLUMN_NAME})
                {
                    $existe = 1;
                }
            }
           
             if($existe == 0)
             {
                $msg .= '<br />Ajout de la colonne <b>'.$col_demozone{COLUMN_NAME}.'</b> dans la table <b>'.$table.'</b>';
                create_col_in_table($dbh,$table,$col_demozone{COLUMN_NAME},$conv_types{$col_demozone{DATA_TYPE}},'',$col_demozone{DATA_TYPE}); 
             }
        }                          
    }
    
    $msg .= '<br /><br />Terminé';
	print $msg;
    exit;
	display($msg);
    exit;
}


sub get_list_of_cols()
{
    #list of COLS
    my @list_of_cols =();
    my $stmt_list_of_cols = "SELECT COLUMN_NAME, DATA_TYPE, COLUMN_DEFAULT FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA ='$_[0]' AND table_name = '$_[1]'";
    my $cursor_list_of_cols = $dbh->prepare($stmt_list_of_cols) || die("CANNOT PREPARE $stmt_list_of_cols");
    $cursor_list_of_cols->execute || suicide($stmt_list_of_cols);
    while ($ref_rec = $cursor_list_of_cols->fetchrow_hashref()) 
    {
        push @list_of_cols,\%{$ref_rec};
    }
    $cursor_list_of_cols->finish;
    return @list_of_cols;
}

sub get_list_of_tables()
{
    #list of TABLES
    my @list_of_tables =();
    my $stmt_list_of_tables = "SELECT t.TABLE_NAME AS stud_tables FROM INFORMATION_SCHEMA.TABLES AS t WHERE t.TABLE_TYPE = 'BASE TABLE' AND t.TABLE_SCHEMA = '$_[0]'";
    my $cursor_list_of_tables = $dbh->prepare($stmt_list_of_tables) || die("CANNOT PREPARE $stmt_list_of_tables");
    $cursor_list_of_tables->execute || suicide($stmt_list_of_tables);
    while ($ref_rec = $cursor_list_of_tables->fetchrow_hashref()) 
  	{
        push @list_of_tables,$ref_rec->{stud_tables};
  	}
  	$cursor_list_of_tables->finish;
    return @list_of_tables;
}

sub create_col_in_table
{
  my $dbh=$_[0];
  my $table=$_[1];
  my $col=$_[2];
  my $type=$_[3];
  my $action=$_[4] || "ADD";
  my $type_source=$_[5] || "";
  
  my $type_stmt = "";
  
  if($type eq 'enum_y_n')
  {
     $type_stmt=" ENUM( 'y', 'n' ) NOT NULL DEFAULT 'n' ";
  }
  elsif($type eq 'enum_n_y')
  {
     $type_stmt=" ENUM( 'y', 'n' ) NOT NULL DEFAULT 'y' ";
  }
  elsif($type eq 'text')
  {
     $type_stmt=" TEXT NOT NULL ";
  }
  elsif($type eq 'change_text')
  {
     $type_stmt=" TEXT CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL  ";
  }
  elsif($type eq 'datetime')
  {
     $type_stmt=" DATETIME NOT NULL ";
  }
  elsif($type eq 'date')
  {
     $type_stmt=" DATE NOT NULL ";
  }
  elsif($type eq 'time')
  {
     $type_stmt=" TIME NOT NULL ";
  }
  elsif($type eq 'int')
  {
     $type_stmt=" INT NOT NULL ";
  }
  elsif($type eq 'int_1')
  {
     $type_stmt=" INT NOT NULL  DEFAULT '1'  ";  
  }
  elsif($type eq 'varchar')
  {
     $type_stmt=" VARCHAR( 255 ) NOT NULL  ";
  }
  elsif($type eq 'float')
  {
     $type_stmt=" FLOAT NOT NULL  ";  
  }
  elsif($type eq 'float_0.21')
  {
     $type_stmt=" FLOAT NOT NULL DEFAULT '0.21'  ";  
  }
  elsif($type eq 'shop_order_status')
  {
     $type_stmt=" ENUM( 'new', 'begin', 'current', 'finished', 'unfinished', 'cancelled' ) NOT NULL DEFAULT 'new' AFTER `id`  ";  
  }
  elsif($type eq 'shop_payment_status')
  {
     $type_stmt=" ENUM( 'wait_payment', 'captured', 'paid', 'repaid', 'cancelled' ) NOT NULL DEFAULT 'wait_payment' AFTER `shop_order_status`  ";  
  }
  elsif($type eq 'shop_delivery_status')
  {
     $type_stmt=" ENUM( 'current', 'ready', 'partial_sent', 'full_sent', 'cancelled','ready_to_take' ) NOT NULL DEFAULT 'current' AFTER `shop_payment_status`   ";  
  }
  elsif($type eq 'longtext')
  {
	$type_stmt =" longtext NOT NULL ";
  }
  my @test=get_describe($dbh,$table);
  if($#test == -1)
  {
      return 0;
  }
  for($t=0;$t<$#test+1;$t++)
  {
      my %line=%{$test[$t]};
      if($line{Field} eq $col)
      {
        return 0;
      }
  }
  
  if($table eq '')
  {
	print "<br>ERR: TABLE EMPTY";
  }
  elsif($col eq '')
  {
	print "<br>ERR: COL EMPTY for $table";
  }
  elsif($type_stmt eq '')
  {
	print "<br>ERR: TYPE EMPTY for col $col (type: $type_source)";
  }
  else
  {
	  my $stmt = "ALTER TABLE `$table` $action `$col` $type_stmt";
	  my $cursor = $dbh->prepare($stmt);
	  my $rc = $cursor->execute;
	  if (!defined $rc) 
	  {
		  see();
		  print "[$stmt]";
		  exit;   
	  }
  }
}