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
$dm_cfg{trad} = 0;
$dm_cfg{tree} = 0;
$dm_cfg{enable_search} = 0;
$dm_cfg{enable_multipage} = 0;
$dm_cfg{excel} =0;
$dm_cfg{visibility} = 0;
$dm_cfg{sort} = 0;
$dm_cfg{edit} = 1;
$dm_cfg{duplicate} = 1;
$dm_cfg{delete} = 1;
$dm_cfg{default_ordby} = 'id asc';
# $dm_cfg{corbeille} = 1;
# $dm_cfg{restauration} = 1;

$dm_cfg{wherep} = $dm_cfg{wherel}  = " migcms_pages_type = 'block' ";
$dm_cfg{table_name} = "migcms_pages";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_pages_blocks.pl?";

$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{after_add_ref} = \&after_save;

my $sel = get_quoted('sel');

$dm_cfg{'list_custom_action_1_func'} = \&custom_block_edit;

$dm_cfg{customtitle} = <<"EOH"; 
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


#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (
	    
      '01/migcms_pages_type'=> 
      {
          'title'=>"Type",
          'fieldtype'=>'text',
          'default_value'=>'block',
		  'mandatory'=>{"type" => 'not_empty'},				
	      'hidden'=>1,
      }
	  ,
	  '02/id_textid_name'=> 
      {
	        'title'=>'Titre',
	        'fieldtype'=>'text_id',
	        'search' => 'y',
	    }
      ,
	  '03/visible_system'	=>{'title'=>'Visible seulement par le rôle system','fieldtype'=>'checkbox','default_value'=>'n','search' => 'n','mandatory'=>{"type" => ''},'tab'=>'','lbtable'=>'','lbkey'=>'','lbdisplay'=>'','lbwhere'=>'','fieldvalues'=>'','hidden'=>0},
	);

%dm_display_fields =  
(
	"01/ID"=>"id",
	"02/$migctrad{blocktypes_name}"=>"id_textid_name",
	"03/$migctrad{blockzonevisiblesystem}"=>"visible_system", 
); 

%dm_lnk_fields = (
		);
                                                         
%dm_mapping_list = (

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

sub custom_block_edit
{
	my $id = $_[0];
	my $colg = $_[1];
	my %page = %{$_[2]};
		
	$link = $config{baseurl}.'/cgi-bin/adm_migcms_parag.pl?type=block&id_page='.$page{id}.'&colg='.$colg.'&sel='.$sel;
	$phrase = "Editer (Ref#$id)";
	$edit_paragraphes = <<"EOH";
		<a href="$link" data-placement="bottom" data-original-title="$phrase" class="btn btn-info "> 
		<i class="fa fa-pencil fa-fw"></i> </a>
EOH
	
	return $edit_paragraphes;
}