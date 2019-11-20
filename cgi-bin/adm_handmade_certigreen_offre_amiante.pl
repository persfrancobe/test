#!/usr/bin/perl -I../lib
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;
use dm_publish_pdf;
use def_handmade;
use File::Copy;


$dbh_data = $dbh2 = $dbh;



$dm_cfg{send_by_email_table_license} = 'handmade_certigreen_licenses';
$dm_cfg{send_by_email_field1_license} = 'license_name';
$dm_cfg{send_by_email_field2_license} = 'email';
$dm_cfg{send_by_email_table_destinataire} = 'members';
$dm_cfg{send_by_email_col_destinataire} = 'id_member';
$dm_cfg{send_by_email_field1_destinataire} = 'fusion_short';
$dm_cfg{send_by_email_field_email_destinataire} = 'email';

#$dm_cfg{send_by_email_field_email_destinataire_func} = 'def_handmade::handmade_emailto_document';
#$dm_cfg{send_by_email_field_email_object_func} = 'def_handmade::handmade_object_document';
#$dm_cfg{send_by_email_field_email_body_func} = 'def_handmade::handmade_body_document';


#$dm_cfg{send_by_email_table_templates} = 'handmade_templates';
$dm_cfg{disable_if_migcms_last_published_file_not_exist} = 'y';



$dm_cfg{enable_search} = 0;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
if($commande_id > 0) {
	$dm_cfg{wherel} = $dm_cfg{wherep} = "commande_id = '$commande_id'";
}

$dm_cfg{table_name} = "handmade_certigreen_document_amiante";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";

$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_handmade_certigreen_offre_amiante.pl?";
$dm_cfg{hide_id} = 0;
$dm_cfg{duplicate}='y';
$dm_cfg{default_ordby}='id desc';

$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{breadcrumb_func}= \&breadcrumb_func;
$dm_cfg{after_add_ref} = \&after_save;
# $dm_cfg{before_del_ref} = \&before_del;
$dm_cfg{autocreation} = 0;


#$dm_cfg{'list_custom_action_14_func'} = \&download_document;
#$dm_cfg{'list_custom_action_15_func'} = \&send_document;
$dm_cfg{'list_custom_action_16_func'} = \&download_communication;


$dm_cfg{file_prefixe} = 'OAM';

my $cpt = 9;
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = 
(

	'02/id_member'=>
	{
		'title'=>'Client',
		'search'=>'y',
		'fieldtype'=>'listboxtable',
		'lbtable'=>'members',
		'lbkey'=>'id',
		'lbdisplay'=>"CONCAT(members.lastname,' ',members.firstname)",
		'lbwhere'=>"" ,

		'mandatory'=>
		{"type" => 'not_empty',
		}

	}
	,
	'04/date_creation'=>
	{
		'title'=>'Date de creation',
		'fieldtype'=>'text',
		'data_type'=>'date',
		'default_value'=>$today,
		'mandatory'=>
		{"type" => 'not_empty',
		}
	}
	,
	'05/site'=>
	{
		'title'=>'Votre de site de ...',
		'fieldtype'=>'text',
		'mandatory'=>
		{"type" => 'not_empty',
		}
	}
	,
	'06/prix_analyse'=>
	{
		'title'=>'Prix des échantillons',
		'fieldtype'=>'text',
		'data_type'=>'euros',
		'mandatory'=>
		{"type" => 'not_empty',
		}
	}

);

%dm_display_fields = 
(
	"09/Date création"=>"date_creation",
	"10/Site"=>"site",
	"11/Prix analyse"=>"prix_analyse",
);


%dm_lnk_fields = 
(      
);
	

%dm_mapping_list = (
);
 
 
 my $js = <<"EOH";
		<style>
		.maintitle
		{
			display:none;
		}
		</style>
		<script type="text/javascript">
			
			jQuery(document).ready( function () 
			{     			    		
			});
      
		</script>
EOH

$dm_cfg{list_html_top} .= $js.def_handmade::get_denom_style_et_js();
$dm_cfg{list_html_top} .=<<"EOH";

<span id="infos_rec"></span>
<script type="text/javascript">
jQuery(document).ready(function() 
{
});

</script>



EOH


sub after_save_all
{
		
}

sub after_save
{
	my $dbh = $_[0];  
  	my $id = $_[1];

	generer_tokens_for_all();
	
	log_debug('after_save_document','vide','after_save_document');
	
	my %offre = read_table($dbh,$dm_cfg{table_name},$id);

	def_handmade::save_offre_amiante_cree_pdf(\%offre);
}

sub generer_tokens_for_all
{
	my @commandes_sans_tokens = sql_lines({select=>"id",dbh=>$dbh, table=>$dm_cfg{table_name}, where=>"token = ''"});
	foreach $commandes_sans_token (@commandes_sans_tokens)
	{
		my %commandes_sans_token=%{$commandes_sans_token};
		my $new_token = create_token(20);

		my $stmt = <<"SQL";
			UPDATE $dm_cfg{table_name}
				SET token = '$new_token'
				WHERE id = '$commandes_sans_token{id}'
SQL
		execstmt($dbh, $stmt);
	}
}




%dm_filters = (
		);


		
$sw = $cgi->param('sw') || "list";

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
    &$sw();
	
	my $js = <<"EOH";
	<script type="text/javascript">
	</script>
EOH
	
    print wfw_app_layout($js.$dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}

sub breadcrumb_func
{
	my $commande_id = get_quoted("commande_id");

#
	# my %commande_document = read_table($dbh,'commande_documents',$id);
	#	my %commande = read_table($dbh,'intranet_factures',$commande_id);
	#	my $fusion = '';
	#	my $rue = trim($commande{adresse_rue}.' '.$commande{adresse_numero});
	#	if($rue ne '')
	#	{
	#	$fusion .= "$rue ";
	#	}
	#	my $ville = trim($commande{adresse_cp}.' '.$commande{adresse_ville});
	#	if($ville ne '')
	#	{
	#	$fusion .= " - $ville ";
	#	}
	#
	#	my $breadcrumb = <<"EOH";
	#	<ol class="breadcrumb">
	#			<li><a href="$url_home">intranet_factures</a></li>
	#			<li><a href="/admin-certigreen/intranet_factures&sel=1000278">Liste des intranet_factures</a></li>
	#			<li><a href="/admin-certigreen/intranet_factures&sel=1000278">Documents de la commande $commande{id} : $fusion</a></li>
	#	</ol>
	#EOH
	return $breadcrumb = '';
	
}


#sub send_document
#{
#	my $id = $_[0];
#	my $colg = $_[1];
##	my %record = %{$_[2]};
#
#	my %record = read_table($dbh,$dm_cfg{table_name},$id);
#
#	my $acces = <<"EOH";
#
#		<a href="#" data-placement="bottom" data-original-title="Déposez d'abord un document pour pouvoir l'envoyer par mail"
#		id="$id" role="button" class="btn btn-link show_only_after_document_ready">
#		<i class="fa fa-paper-plane-o  fa-fw" data-original-title="" title=""></i></a>
#EOH
#
#	if($record{migcms_last_published_file} ne '' && $record{migcms_last_published_file} ne '/')
#	{
#		$acces = <<"EOH";
#
#		<a href="#" data-placement="bottom" data-original-title="Envoyer le document par email"
#		id="$id" role="button" class="btn btn-default show_only_after_document_ready send_by_email">
#		<i class="fa fa-paper-plane-o  fa-fw" data-original-title="" title=""></i></a>
#EOH
#	}
#
#
#
#	return $acces;
#}

#
#sub download_document
#{
#	my $id = $_[0];
#	my $colg = $_[1];
##	my %record = %{$_[2]};
#	my $self = "$config{baseurl}/cgi-bin/adm_migcms_codes.pl?sel=".get_quoted('sel').'&id_code_type='.$id;
#
#	my %record = read_table($dbh,$dm_cfg{table_name},$id);
##see(\%record);
#
#
#	my $acces = <<"EOH";
#
#		<a href="#"  data-placement="bottom"
#		 data-original-title="Déposez'abord un document PDF pour pouvoir le télécharger" role="button" class="btn btn-link show_only_after_document_ready ">
#		 <i class="fa fa-eye  fa-fw" data-original-title="" title=""></i></a><!-- [$record{migcms_last_published_file}]-->
#EOH
#
#	if($record{migcms_last_published_file} ne '' && $record{migcms_last_published_file} ne '/')
#	{
#		$record{migcms_last_published_file} =~ s/\.\.\//\.\.\/usr\//g;
#		$acces = <<"EOH";
#
#		<a href="$record{migcms_last_published_file}"  data-placement="bottom" target="_blank"
#		 data-original-title="Télécharger le document PDF $record{migcms_last_published_file}" role="button" class="btn btn-default show_only_after_document_ready ">
#		 <i class="fa fa-eye  fa-fw" data-original-title="" title=""></i></a>
#EOH
#	}
#
#	return $acces;
#}

sub download_communication
{
	my $id = $_[0];
	my $colg = $_[1];
#	my %record = %{$_[2]};
	my $self = "$config{baseurl}/cgi-bin/adm_migcms_codes.pl?sel=".get_quoted('sel').'&id_code_type='.$id;
	my %offre = read_table($dbh,$dm_cfg{table_name},$id);




	my $acces = <<"EOH";

		<a href="#"  data-placement="bottom"
		 data-original-title="Sauvegardez le document pour générer l'offre PDF" role="button" class="btn btn-link show_only_after_document_ready ">
		 <i class="fa fa-eye  fa-fw" data-original-title="" title=""></i></a>
EOH

	my $filepath = '../usr/documents/offre_amiante_'.$offre{id}.'_'.$offre{token}.'.pdf';
	if(-e $filepath)
	{
		$acces = <<"EOH";

		<a href="$filepath"  data-placement="bottom" target="_blank"
		 data-original-title="Télécharger la communication pour ce document" role="button" class="btn btn-default show_only_after_document_ready ">
		 <i class="fa fa-eye  fa-fw" data-original-title="" title=""></i></a>
EOH
	}

	return $acces;
}

