#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;
use Data::Dumper;
         # migc translations
use migcrender;
use mailing;


#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###############################################################################################
####################################	CODE DU PROGRAMME		######################################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


my $id_mailing = get_quoted('id_mailing');
$colg = get_quoted('colg') || $config{default_colg} || 1;
my $htaccess_ssl = $config{rewrite_ssl};
my $htaccess_protocol_rewrite = "http";
if($htaccess_ssl eq 'y') {
  $htaccess_protocol_rewrite = "https";
}

$dm_cfg{customtitle} = "Envoi d'une newsletter";
$dm_cfg{enable_search} = 0;
$dm_cfg{enable_multipage} = 0;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
# $dm_cfg{wherel} = "id_textid_name=txt.id_textid AND txt.id_language=$config{current_language}";
$dm_cfg{wherep} = "id_mailing=$id_mailing";
$dm_cfg{wherel} = "id_mailing=$id_mailing";

$dm_cfg{table_name} = "mailing_sendings";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";

$self = $dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_mailing_sendings.pl?id_mailing=$id_mailing&colg=".$colg;
$dm_cfg{disable_mod}   = "y";
    
 my @abc = qw(
 a
 b
 c
 d
 e
 f
 g
 h
 i 
 j
 k
 l
 m
 n
 o
 p
 q
 r
 s
 t
 u
 v
 w
 x
 y
 z
 );
 
$dm_cfg{hiddp}=<<"EOH";
<input type="hidden" name="id_mailing" value="$id_mailing" />
<input type="hidden" name="colg" value="$colg" />
EOH

%status = (
			"running"=>"$migctrad{yes}",
			"ok"=>"$migctrad{no}"
		);

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (
	    '01/id_mailing'=> {
	        'title'=>$migctrad{adm_mailing_sends_idmailing},
	        'fieldtype'=>'display'
	    },
	     '02/begin_moment'=> {
	        'title'=>$migctrad{adm_mailing_sends_begin_moment},
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty'},
	    }
	    ,
	     '03/end_moment'=> {
	        'title'=>$migctrad{adm_mailing_sends_end_moment},
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty'},
	    }
	    ,
	     '04/nb_sent'=> {
	        'title'=>$migctrad{adm_mailing_sends_nb_sent},
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty'},
	    }
	    ,
	     '06/nb_view'=> {
	        'title'=>$migctrad{adm_mailing_sends_nb_view},
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty'},
	    }
	    ,
	     '07/nb_clicks'=> {
	        'title'=>$migctrad{adm_mailing_sends_nb_clicks},
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty'},
	    },
	    ,
	     '08/nb_uview'=> {
	        'title'=>$migctrad{adm_mailing_sends_nb_uview},
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty'},
	    }
	    ,
	     '09/nb_uclicks'=> {
	        'title'=>$migctrad{adm_mailing_sends_nb_uclicks},
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty'},
	    },
	    ,
	     '10/nb_err'=> {
	        'title'=>$migctrad{adm_mailing_sends_nb_err},
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty'},
	    }
	    ,
	     '11/nb_unsub'=> {
	        'title'=>$migctrad{adm_mailing_sends_nb_unsub},
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty'},
	    } ,

	);
#"01/$migctrad{id_textid_name}"=>"txt.content\@"
%dm_display_fields = (
	"01/Date"=>"begin_moment",
	"03/Expéditeur"=>"adrfrom",
	"04/Objet"=>"subject",
	"05/$migctrad{adm_mailing_sends_nb_sent}"=>"nb_sent",
	"06/$migctrad{adm_mailing_sends_nb_view}"=>"nb_view",
	"08/$migctrad{adm_mailing_sends_nb_clicks}"=>"nb_clicks",
	"10/Erreur"=>"nb_err",
	"11/Désinscription"=>"nb_unsub",

		);
		
# "02/$migctrad{edit}/$migcicons{edit}"=>"adm_mailing_members.pl?&id_mailing_group=",
%dm_lnk_fields = (
#	"03/$migctrad{adm_mailing_sends_nb_sent}"=>"nb_sent*",
#	"04/$migctrad{adm_mailing_sends_nb_view}"=>"nb_view*",
#	"05/$migctrad{adm_mailing_sends_nb_good}"=>"nb_good*",
#	"06/$migctrad{adm_mailing_sends_nb_clicks}"=>"nb_clicks*",

# "07/Stats/Voir"=>$self."&sw=get_stats&id=",
 "12/Détail/Voir"=>$self."&sw=get_stats&id=",
		);

%dm_mapping_list = (
#"nb_sent"=>\&get_nb_sent,
#"nb_view"=>\&get_nb_view,
#"nb_good"=>\&get_nb_good,
#"nb_clicks"=>\&get_nb_clicks,

);

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
			up
			send_mailing_choose_groups
                     get_stats
                     preview_nl_html
		);

if (is_in(@fcts,$sw)) 
{ 
    dm_init();
    if ($sw eq "list") {
        update_stats();
    }
    &$sw();
    $migc_output{content} .= $dm_output{content};
    $migc_output{title} = $dm_output{title}.$migc_output{title};
    
    print migc_app_layout($migc_output{content},$migc_output{title},"",$gen_bar,$spec_bar);
}

sub mailing_send
{
    my $id_mailing=get_quoted('id_mailing');
    see();
    print "send mailing #$id_mailing";
}

sub send_mailing_choose_groups 
{
	if($config{mailing_choose_groups_custom_func} ne '')
	{
		$migc_output{content} = $display;	
	} 
 
	my $id_mailing = $cgi->param('id_mailing');
	my %mailing = read_table($dbh,"mailings",$id_mailing);
	my $display = "";

	my $campagnes = '<table id="migc4_main_table" class="table table-bordered table-striped table-condensed cf table-hover">';
	$campagnes .= <<"EOH";
		<tr>
			<th class="mig_cb_col"></th>
			<th>
				Nom de l'action
			</th>
			<th>
				Type de campagne
			</th>
			<th>
				Nom de la campagne
			</th>
		</tr>
EOH

	my @handmade_medimerck_campagnes = sql_lines({debug=>0,debug_results=>0,select=>"handmade_medimerck_actions.name as name_action, handmade_medimerck_campagnes.name as name_campagne,handmade_medimerck_campagnes.id as id,handmade_medimerck_campagne_types.name as name_campagne_type",table=>'handmade_medimerck_campagnes,handmade_medimerck_actions,handmade_medimerck_campagne_types',where=>"handmade_medimerck_campagne_types.id=1 AND handmade_medimerck_campagne_types.id = handmade_medimerck_campagnes.id_handmade_medimerck_campagne_type AND handmade_medimerck_campagnes.id_action = handmade_medimerck_actions.id",ordby=>'handmade_medimerck_actions.name,handmade_medimerck_campagnes.name'});
	foreach $handmade_medimerck_campagne (@handmade_medimerck_campagnes)
	{
		%handmade_medimerck_campagne = %{$handmade_medimerck_campagne};
		
		$campagnes .= <<"EOH";
		<tr>
			<td class="text-center td-input">
				<input type="radio" $checked class="id_campagne form-control" name="id_campagne" value="$handmade_medimerck_campagne{id}" />
			</td>
			<td class="td-cell-value cms_mig_cell">
				<span class="cell-value">$handmade_medimerck_campagne{name_action}</span>
			</td>
			<td class="td-cell-value cms_mig_cell">
				<span class="cell-value">$handmade_medimerck_campagne{name_campagne_type}</span>
			</td>
			<td class="td-cell-value cms_mig_cell">
				<span class="cell-value">$handmade_medimerck_campagne{name_campagne}</span>
			</td>
		</tr>
EOH
	}

	$campagnes .= <<"EOH";
		</table>	
		<div class="col-md-12 text-right">
			<a type="" class="btn btn-lg btn-link show_only_after_document_ready cancel_edit" aria-hidden="true">
				<i class="fa fa-arrow-left"></i> Retour
			</a>
			<button type="submit" class="btn btn-lg btn-success show_only_after_document_ready save_campagne">
				Suivant <i class="fa fa-arrow-right"></i>
			</button>
		</div>  
EOH
 

 $display =<<"EOH";
<div class="wrapper">
	<div class="header-actions">
	<div class="row">
	<div class="col-lg-8">
	<h1 class="maintitle">Newsletter > Destinataires</h1>
	</div>
	</div>

	<div class="row">
		<div class="col-sm-12">
			<section class="panel">
				<div class="panel-body">
	<form action="$self" method="post">
	<input type="hidden" name="sw" value="send_mailing_confirm_form" />
	<input type="hidden" name="id_mailing" value="$id_mailing" />
	<input type="hidden" name="nbgroup" value="$igroup" /> 
	<input type="hidden" name="colg" value="$colg" />
	<div class="alert alert-info">
		<i class="fa fa-info-circle"></i> Choisissez le groupe de membres auquel vous désirez envoyer la newsletter.
	</div>
	<fieldset class="mig_fieldset2">
		<div class="mig_add_update_form_content">
			$campagnes
		</div>
	</fieldset>
	</form>
				</div>
			</section>
		</div>
	</div>
</div>
EOH
   
$migc_output{content} = $display;
}

# sub send_mailing_choose_groups 
# {
	# if($config{mailing_choose_groups_custom_func} ne '')
	# {
		# $migc_output{content} = $display;	
	# } 
 
	# my $id_mailing = $cgi->param('id_mailing');
	# my %mailing = read_table($dbh,"mailings",$id_mailing);
	# my $display = "";
	# my $list_groups = '<table class="table">';
 
    # my @mailing_groups = sql_lines({table=>'mailing_groups',ordby=>'title',where=>""});
	# foreach $mailing_group (@mailing_groups)
	# {
		# my %mailing_group = %{$mailing_group};
		# my %count_mailing_group = sql_line({select=>"count(*) as nb",table=>'migcms_members',where=>"id_mailing_group = '$mailing_group{id}' "});
		# $list_groups .= <<"EOH";
		# <tr><td><label><input type="radio" name="id_mailing_group" value="$mailing_group{id}" /> $mailing_group{title}</label></td><td><span class="badge">$count_mailing_group{nb} inscrits</span></td></tr>
# EOH
	# }
 

 # $display =<<"EOH";
 

# <div class="well">
 
# <form action="$self" method="post">
# <input type="hidden" name="sw" value="send_mailing_confirm_form" />
# <input type="hidden" name="id_mailing" value="$id_mailing" />
# <input type="hidden" name="nbgroup" value="$igroup" /> 
# <input type="hidden" name="colg" value="$colg" /> 
# <fieldset class="mig_fieldset2">
	# <h2 class="mig_legend">Newsletter > Destinataires</h2>
	# <div class="mig_add_update_form_content">
# <i class="fa fa-info"></i> Choisissez le groupe de membres auquel vous désirez envoyer la newsletter, puis appuyer sur "Continuer":<br><br>
# $list_groups</table>
	# </div>
# </fieldset>
# <table id="mig_button_content">
	# <tr>
		# <td>
			# <br><br><button class="btn btn-primary" type="submit">Continuer &gt;</button>
		# </td>
	# </tr>
# </table>
# </form>

# </div>

# EOH

   
   
   
# $migc_output{content} = $display;

# }

sub send_mailing_confirm_form 
{
	my $id_mailing = $cgi->param('id_mailing');
	# my $id_mailing_group = $cgi->param('id_mailing_group');
	my $id_campagne = $cgi->param('id_campagne');
	# my %mailing = read_table($dbh,"mailings",$id_mailing);
	my %campagne = read_table($dbh,'handmade_medimerck_campagnes',$id_campagne);
	my %action = read_table($dbh,'handmade_medimerck_actions',$campagne{id_action});

	if(!($campagne{id} > 0))
	{
		make_error("Choissez une campagne svp");   
	}
	if(!($action{id} > 0))
	{
		make_error("Choissez une action svp");   
	}
	
	my @where_action = ();
	
	if($action{id_member_group} > 0)
	{
		push @where_action, " id_member_group = '$action{id_member_group}' ";
	}
	if($action{section} > 0)
	{
		push @where_action, " section = '$action{section}' ";
	}
	if($action{segmentation} > 0)
	{
		push @where_action, " ( segmentation_a = '$action{segmentation}' OR segmentation_b = '$action{segmentation}' OR segmentation_c = '$action{segmentation}') ";
	}
	if($action{specialite} > 0)
	{
		push @where_action, " specialite = '$action{specialite}' ";
	}
	if($action{language} ne '')
	{
		push @where_action, " language = '$action{language}' ";
	}
	if($action{email_optin} ne '')
	{
		push @where_action, " email_optin = '$action{email_optin}' ";
	}
	my $where_action = join(" AND ",@where_action);

	my %nb = sql_line({debug=>1,debug_results=>1,select=>"COUNT(*) as nb_destinataires",table=>'migcms_members',where=>"$where_action AND email NOT IN (select distinct email from mailing_blacklist)"});
	if(!($nb{nb_destinataires} > 0))
	{
		make_error("Aucun destinataire trouvé.");   
	}
	my $premiers = '';
	my @firsts = sql_lines({debug=>1,debug_results=>1,select=>"firstname,lastname,email",table=>'migcms_members',where=>"$where_action AND email NOT IN (select distinct email from mailing_blacklist)",limit=>'0,10'});
	foreach $first (@firsts)
	{
		my %first = %{$first};
		$premiers .= "<br>$first{firstname} $first{lastname} - $first{email}";
		
	}

 
    my $display = "";  

 
 my $backlinks = <<"EOH";
<p class="txt_exp">
confirmation de l'envoi de <strong> $mailing{title} </strong>
</p>  
EOH
 my %mailing = read_table($dbh,'mailings',$id_mailing);
 my %migcms_page = read_table($dbh,'migcms_pages',$mailing{id_migcms_page});
 my $preview_link = "../cgi-bin/migcms_view.pl?id_page=$migcms_page{id}&lg=$colg&mailing=y";

 my $migcms_page_name = get_traduction({debug=>0,id_language=>$lg,id=>$migcms_page{id_textid_name}});

 
 
 $display =<<"EOH";
<div class="wrapper">
	<div class="header-actions">
	<div class="row">
	<div class="col-lg-8">
	<h1 class="maintitle">Newsletter > Confirmation</h1>
	</div>
	</div>

	<div class="row">
		<div class="col-sm-12">
			<section class="panel">
				<div class="panel-body">
					<div class="alert alert-success">
						<h1 style="font-size:20px;margin:0px;">Désirez vous envoyer :</h1>
					</div>
					<ul>
						<li><strong>$nb{nb_destinataires}</strong> email(s)<br />
						<div class="alert alert-info">
							<i class="fa fa-info-circle"></i> <strong>Apercu des destinataires</strong><br />
							$premiers
							<br />...
						</div></li>
						<li>Provenant de : <strong>$mailing{sender_name} &lt;$mailing{sender_email}&gt;</strong></li>
						<li>Avec pour objet de l'email : <strong>$migcms_page_name</strong></li>
						<li>Avec pour contenu <strong><a href="$preview_link" target="_blank" style="color: #7a7676;text-decoration:underline;">cette newsletter</a></li></strong>
					</ul>
					<form method="post" action="$self">
						<input type="hidden" value="send_mailing_confirm_db" name="sw" />
						<input type="hidden" value="$id_mailing" name="id_mailing" />
						<input type="hidden" value="$id_mailing_group" name="id_mailing_group" />
						<input type="hidden" value="$id_campagne" name="id_campagne" />
						<input type="hidden" value="$colg" name="colg" />
						$destinataires
						<br />
						<div class="text-center">
							<a href="$config{baseurl}/cgi-bin/adm_migcms_mailings.pl?&sel=166" class="btn-danger btn btn-lg">Annuler l'envoi</a>
							<button class="btn-success btn btn-lg" type="submit">Confirmer l'envoi</button>
						</div>
					</form>
				</div>
			</section>
		</div>
	</div>
</div>


EOH

#<A HREF="$self&sw=send_nl_go&nl=$nl&val=$grpurl">Oui, je confirme l'envoi</A><BR><BR>

 
$migc_output{content} = $display;

}

sub send_mailing_confirm_db 
{
	my $id_mailing = $cgi->param('id_mailing');
	my $id_campagne = $cgi->param('id_campagne');
	my $id_mailing_group = $cgi->param('id_mailing_group');
	my %mailing = read_table($dbh,"mailings",$id_mailing);

	if(!($id_mailing > 0) && !($id_campagne > 0))
	{
		make_error("Choissez une campagne svp");   
		exit;
	}

	my %campagne = read_table($dbh,'handmade_medimerck_campagnes',$id_campagne);
	my %action = read_table($dbh,'handmade_medimerck_actions',$campagne{id_action});

	if(!($campagne{id} > 0))
	{
		make_error("Choissez une campagne svp");   
	}
	if(!($action{id} > 0))
	{
		make_error("Choissez une action svp");   
	}
	
	my @where_action = ();
	
	if($action{id_member_group} > 0)
	{
		push @where_action, " id_member_group = '$action{id_member_group}' ";
	}
	if($action{section} > 0)
	{
		push @where_action, " section = '$action{section}' ";
	}
	if($action{segmentation} > 0)
	{
		push @where_action, " ( segmentation_a = '$action{segmentation}' OR segmentation_b = '$action{segmentation}' OR segmentation_c = '$action{segmentation}') ";
	}
	if($action{specialite} > 0)
	{
		push @where_action, " specialite = '$action{specialite}' ";
	}
	if($action{language} ne '')
	{
		push @where_action, " language = '$action{language}' ";
	}
	if($action{email_optin} ne '')
	{
		push @where_action, " email_optin = '$action{email_optin}' ";
	}
	my $where_action = join(" AND ",@where_action);
	if($where_action eq '')
	{
		$where_action = 0;
	}
	my %nb = sql_line({debug=>0,debug_results=>0,select=>"COUNT(*) as nb_destinataires",table=>'migcms_members',where=>"$where_action AND email NOT IN (select distinct email from mailing_blacklist)"});
	if(!($nb{nb_destinataires} > 0))
	{
		make_error("Aucun destinataire trouvé dans ce groupe.");   
		exit;
	}
	
	my $from = "$mailing{sender_name} <$mailing{sender_email}>";
    $from =~ s/\'/\\\'/g;
	
	my $subject = $subject_raw = "$mailing{email_subject}";
	$subject =~ s/\'/\\\'/g;
	
	#rendu de la page
	my $email_body = $email_body_raw = render_page({mailing=>'y',debug=>0,id=>$mailing{id_migcms_page},lg=>$lg,preview=>'y',edit=>'n'});
	$email_body =~ s/\'/\\\'/g;
    $email_body =~ s/\&amp;/\&/g;

	#creer un sending pour ce mailing
	my %sending = 
	(
	   id_mailing => $id_mailing,
	   begin_moment=>'NOW()',
	   subject=>$subject,
	   adrfrom=>$from,
	   content=>$email_body,
	);
	my $id_sending = inserth_db($dbh,"mailing_sendings",\%sending);
	
	# envoie le sending sur le serveur
	$dbh_send = DBI->connect($config{db_qm},$config{login_qm},$config{passwd_qm}) or suicide("cannot connect to sending DB");
    my $idsending = create_migc_mailing($dbh_send,$subject_raw,$from,$subject_raw,$email_body_raw,$id_sending,$mailing_cfg);
	
	#maj de mailing sur le serveur
	execstmt($dbh_send,"SET NAMES utf8");
	execstmt($dbh_send,"SET CHARSET utf8");   
	$stmt = "UPDATE mailings SET  from_email = '$from',content='$email_body',subject='$subject' WHERE id = $idsending";
	execstmt($dbh_send,$stmt);
	
	my $url_unsubscribe = "$config{fullurl}/cgi-bin/nl.pl?sw=unsubscribe_db&nl=$id_sending&email=";
	
	#boucler sur les membres
	my @migcms_members = sql_lines({debug=>0,debug_results=>0,table=>'migcms_members',where=>"$where_action AND email != '' AND email NOT IN (select distinct email from mailing_blacklist)"});
	foreach $migcms_member (@migcms_members)
	{
		my %migcms_member = %{$migcms_member};
		# see(\%migcms_member);
		# exit;
		#ajouter une queue pour ce sending (avec statut wait)
		$f1 = $migcms_member{stoken};
		my @t_data = ($f1,$f2,$f3,$f4,$f5);
		
        create_migc_mq($dbh_send, $idsending , $migcms_member{email} ,\@t_data,$url_unsubscribe,\%mailing_cfg);
	}
	
	#faire passer le sending en actif
	$stmt = "UPDATE mailing_sendings SET status='sending' WHERE id  = $id_sending";
    execstmt($dbh,$stmt); 
       	
	http_redirect("$self&sw=send_mailing_ok");
}

sub send_mailing_pay_form {
 http_redirect("$self&sw=send_mailing_pay_db");
}

sub send_mailing_pay_db {
 http_redirect("$self&sw=send_mailing_start_send");
}

sub send_mailing_start_send {
 http_redirect("$self&sw=send_mailing_ok");

}

sub send_mailing_ok {

$migc_output{content}=<<"EOH";
<div class="wrapper">
	<div class="header-actions">
	<div class="row">
	<div class="col-lg-8">
	<h1 class="maintitle">Newsletter > Envoyé</h1>
	</div>
	</div>

	<div class="row">
		<div class="col-sm-12">
			<section class="panel">
				<div class="panel-body">
					<div class="alert alert-success" style="margin:0px;">
						<h1 style="font-size:20px;margin:0px 0px 15px 0px;">Votre newsletter a bien été envoyée.</h1>
						<p>Son envoi peut durer un moment, en fonction de la disponibilité du serveur d'envoi.<br /><br />
						Vous recevrez un email de confirmation lorsque l'envoi sera terminé.<br /><br />
						<a href="$config{baseurl}/cgi-bin/adm_migcms_mailing_sendings.pl?id_mailing=$id_mailing&sel=166" style="font-weight:bold;text-decoration:underline;color:#3c763d;">Consultez l'historique</a> des envois pour les données précises concernant votre newsletter (nombre de lectures, nombre de clicks,...).</p>
					</div>
				</div>
			</section>
		</div>
	</div>
</div>
EOH

}


#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------


###############################################################################
# CREATE_MIGC_MAILING
###############################################################################

sub create_migc_mailing
{
 my $dbh_send = $_[0];
 my $name = $_[1];
 my $from_email = $_[2];
 my $subject = $_[3];
 my $content = $_[4];
 my $id_nl = $_[5];
 
 log_to("orig_content : $content");

 $name =~ s/\'/\\\'/g;
 $subject =~ s/\'/\\\'/g;
 $content =~ s/\'/\\\'/g;
 $content =~ s/<br \/>/<br \/>\r\n/g;
 $content =~ s/<\/p>/<\/p>\r\n/g;
 $from_email =~ s/\'/\\\'/g;

# 
#   $content = from_utf8({ -string => $content, -charset => 'ISO-8859-1' });
#   $subject = from_utf8({ -string => $subject, -charset => 'ISO-8859-1' });
 
# $content = "xxx"; 
  
#  use Encode;
#  $content = encode("iso-8859-1", $content);
#  $subject = encode("iso-8859-1", $subject);
#  execstmt($dbh_send,"SET NAMES latin1");
# execstmt($dbh_send,"SET CHARSET latin1");
 
 my $stmt = "INSERT INTO mailings (mailing_name, from_email, subject, content, queued_time, status, nbsent,dbname,id_nl) VALUES ('$name','$from_email','$subject', '$content', NOW(),'started','0','$config{db_name}','$id_nl')";
 execstmt($dbh_send,$stmt);
 my $id_mailing = $dbh_send->{'mysql_insertid'};
 log_to("id_mailing : $id_mailing");
 log_to("content : $content");
 return $id_mailing;
}

###############################################################################
# CREATE_MIGC_MQ
###############################################################################

sub create_migc_mq
{
 my $dbh = $_[0];
 my $id_mailing = $_[1];
 my $to_email = $_[2];
 my @specdata = @{$_[3]};
 my $url_unsub = $_[4];
 my %cfg = %{$_[5]};


 my @fields = ();
 my @values = ();
 for (my $i = 0; $i<=$#specdata; $i++) {
      my $j = $i+1;
      if ($specdata[$i] ne "") {
          $specdata[$i] =~ s/\'/\\\'/g;
          push @fields,"qmdata".$j;
#           my $val =  from_utf8({ -string => $specdata[$i], -charset => 'ISO-8859-1' });
          my $val =   $specdata[$i];
          push @values,$val;                 
      }
 
 }
 my $dfields = "";
 my $dvals = "";
 if ($#values > -1) {
     $dfields = ",".join(",",@fields);     
     $dvals = ",'".join("','",@values)."'";     
 }


 my $stmt = "INSERT INTO queue (id_mailing, to_email,queued_on,status,url_unsub,no_count $dfields) VALUES ('$id_mailing','$to_email', NOW(),'wait','$url_unsub','$cfg{no_count}' $dvals)";
 execstmt($dbh,$stmt);
}


sub update_stats
{
$dbh_send = DBI->connect($config{db_qm},$config{login_qm},$config{passwd_qm}) or die("cannot connect to sending DB : $DBI::errstr");

my $stmt = "SELECT id,id_mailing from mailing_sendings";
my  $cursor = $dbh->prepare($stmt);
$cursor->execute || die("error execute : $DBI::errstr [$stmt]\n");
 while (($id_sending,$id_mailing) = $cursor->fetchrow_array()) {

    $stmt = "SELECT id,status,nbsent,nbopen,nbclick,nbuopen,nbuclick,from_email,subject,content from mailings WHERE id_nl='$id_sending' AND dbname='$config{db_name}' ORDER BY id desc";
    my  $cursor2 = $dbh_send->prepare($stmt);
    $cursor2->execute || die("error execute : $DBI::errstr [$stmt]\n");
    my ($id_mailing_ext,$status,$nbsent,$nbopen,$nbclick,$nbuopen,$nbuclick,$from,$subject,$content) = $cursor2->fetchrow_array();
    $cursor2->finish;

    $from =~ s/\'/\\\'/g;
    $subject =~ s/\'/\\\'/g;
    $content =~ s/\'/\\\'/g;

    $stmt = "SELECT to_email,err_dt FROM queue WHERE id_mailing='$id_mailing_ext' AND has_error = 'y'";
    my  $cursor2 = $dbh_send->prepare($stmt);
    $cursor2->execute || die("error execute : $DBI::errstr [$stmt]\n");
    my $email = "";
    my $nberr = 0;

    while (($email,$err_dt) = $cursor2->fetchrow_array()) {

        $stmt = "SELECT id FROM mailing_members WHERE email = '$email'";
        my  $cursor3 = $dbh->prepare($stmt);
        $cursor3->execute || die("error execute : $DBI::errstr [$stmt]\n");
        my ($id_member) = $cursor3->fetchrow_array();
        $cursor3->finish();
        
        $stmt = "delete from mailing_members where id = '$id_member'";
        execstmt($dbh,$stmt);

        $stmt = "delete from mailing_lnk_member_groups where id_mailing_member = '$id_member'";
        execstmt($dbh,$stmt);
        
        if ($id_member ne '') {

            $stmt = "insert into mailing_blacklist (id_mailing,id_sending,email,moment,reason) values ($id_mailing,$id_sending,'$email',NOW(),'error')";
            execstmt($dbh,$stmt);
        }

        $nberr++;
    }
    $cursor2->finish;

    $stmt = "SELECT count(*) from mailing_blacklist WHERE id_sending='$id_sending' and reason='unsubscribe'";
    my  $cursor2 = $dbh->prepare($stmt);
    $cursor2->execute || die("error execute : $DBI::errstr [$stmt]\n");
    my ($cnt) = $cursor2->fetchrow_array();
    $cursor2->finish;

     $stmt2 = "update mailing_sendings set nb_sent='$nbsent',nb_view='$nbopen',nb_clicks='$nbclick',nb_uview='$nbuopen', nb_uclicks='$nbuclick', nb_err='$nberr', nb_unsub='$cnt', status='$status', adrfrom='$from', subject='$subject',content='$content' where id = $id_sending";
     execstmt($dbh,$stmt2);

 }
 $cursor->finish;
 

}



#################

sub get_nb_sent
{
 my $dbh = $_[0];
 my $id = $_[1];

 if ($id == 6) {
     return "2439";
 } else {

     my %sending = read_table($dbh,"mailing_sendings",$id);
     return $sending{nb_sent};
 }
}

sub get_nb_view
{
 my $dbh = $_[0];
 my $id = $_[1];

 if ($id == 6) {
     return "674";
 } else {

     my %sending = read_table($dbh,"mailing_sendings",$id);
     return $sending{nb_view};
 }
}

sub get_nb_good
{
 my $dbh = $_[0];
 my $id = $_[1];

 if ($id == 6) {
     return "2174";
 } else {

     my %sending = read_table($dbh,"mailing_sendings",$id);
     return $sending{nb_good};
 }
}


sub get_nb_clicks
{
 my $dbh = $_[0];
 my $id = $_[1];

 if ($id == 6) {
     return "315";
 } else {

     my %sending = read_table($dbh,"mailing_sendings",$id);
     return $sending{nb_clicks};
 }
}



sub get_stats
{

 my $id_mailing = get_quoted('id_mailing');
 my $id_sending = get_quoted('id');

 $dbh_send = DBI->connect($config{db_qm},$config{login_qm},$config{passwd_qm}) or suicide("cannot connect to sending DB");

my %sending = select_table($dbh,"mailing_sendings","*","id=$id_sending");
my %sending_ext = select_table( $dbh_send,"mailings","*","id_nl='$id_sending' AND dbname='$config{db_name}'");

my $delivery_stats = get_stats_delivery($dbh,$dbh_send,$id_mailing,$id_sending,\%sending,\%sending_ext);
 my $click_stats = get_stats_clicks($dbh,$dbh_send,$id_mailing,$id_sending,\%sending,\%sending_ext);
 my $timeline_stats = get_stats_timeline($dbh,$dbh_send,$id_mailing,$id_sending,\%sending,\%sending_ext);

$migc_output{content} = <<"EOH";
<script type="text/javascript" src="../mig_skin/js/highcharts.js"></script>
<script type="text/javascript" src="../mig_skin/js/highcharts_exporting.js"></script>	

<style>

.stat_graph {
float:left;
}


.stat_tab
{
 text-align:center;
clear:both;
float:right;
width:400px;
}

.stat_tab2
{
 text-align:center;
clear:both;
float:right;
width:600px;
}

.stat_tab table,
.stat_tab2 table
{
 border:1px solid grey;
 border-collapse:collapse;

}


.stat_tab table td,
.stat_tab table th,
.stat_tab2 table td,
.stat_tab2 table th

{
 border:1px solid grey;
 padding:5px;
}


.stat_tab table td.stat_title,
.stat_tab2 table td.stat_title
{
text-align:left;
color:#666666;
}

.stat_tab table td.stat_data,
.stat_tab2 table td.stat_data
{
text-align:right;
font-weight:bold;
color:#000000;
}


h1
{
 border-bottom:1px solid grey;
 margin:40px;
 padding:40px;
 padding-bottom:5px;

display:block;
clear:both;
text-align:center;
color:#444444;
font-size:13pt;
font-weight:normal;
}

h1 span
{
color:#777777;
font-style:italic;
}

.container
{
 width:100%;
border:0;
display:block;
text-align:center;
}
.graph_gfx
{
 border:1px solid grey;
 float:left;
 width:650px;
 margin-left:10px;
 padding:10px;
}

.graph_gfx2
{
 border:1px solid grey;
 float:left;
 width:450px;
 margin-left:10px;
 padding:10px;
}
</style>

		

<center>
<div class="container">

<h1><b>DELIVERY</b> of mailing<br /><span>"$sending{subject}"</span></h1>
$delivery_stats

<h1><b>LINKS</b> in mailing<br /> <span>"$sending{subject}"</h1>

$click_stats

<h1><b>TIMELINE</b> of mailing<br /> "$sending{subject}"</h1>

$timeline_stats

</div>
</center>
EOH


}

sub get_stats_delivery
{
 my $dbh = $_[0];
 my $dbh_mailer = $_[1];
 my $id_mailing = $_[2];
 my $id_sending = $_[3];
 my %sending = %{$_[4]};
 my %sending_ext = %{$_[5]};



 
 
 
 my $read = $sending{nb_view};
 my $click = $sending{nb_clicks};
 my $unsub = $sending{nb_unsub};
 my $err = $sending{nb_err};
 my $sent = $sending{nb_sent};


 my $not_read = $sent - $read - $err;
 $read -= $click;
 $read -= $unsub;

my $html = <<"EOH";
 
<div class="stat_tab">
  <table>
  <tr><th colspan="2">Delivery Status</th></tr>
  <tr><td class="stat_title">ERROR</td><td class="stat_data">$err</td></tr>
  <tr><td class="stat_title">NOT READ</td><td class="stat_data">$not_read</td></tr>
  <tr><td class="stat_title">READ</td><td class="stat_data">$read</td></tr>
  <tr><td class="stat_title">READ + CLICK</td><td class="stat_data">$click</td></tr>
  <tr><td class="stat_title">READ + UNSUBSCRIBE</td><td class="stat_data">$unsub</td></tr>
  <tr><td class="stat_title">TOTAL SENT</td><td class="stat_data">$sent</td></tr>
  </table>
</div><div id="stat_graph_delivery" class="graph_gfx"></div>
<script type="text/javascript">

 \$(document).ready(function() {
\$('#stat_graph_delivery').highcharts({
            chart: {
                plotBackgroundColor: null,
                plotBorderWidth: null,
                plotShadow: false
            },
            title: {
                text: 'Delivery rates'
            },
            tooltip: {
        	    pointFormat: '{series.name}: <b>{point.percentage}%</b>',
            	percentageDecimals: 1
            },
            plotOptions: {
                pie: {
                    allowPointSelect: true,
                    cursor: 'pointer',
                    dataLabels: {
                        enabled: true,
                        color: '#000000',
                        connectorColor: '#000000',
                        formatter: function() {
                            return '<b>'+ this.point.name +'</b>: '+ this.percentage.toFixed(2) +' %';
                        }
                        
                    }
                }
            },
            series: [{
                type: 'pie',
                name: 'Delivery',
                data: [
		  ['ERROR', $err],
		  ['NOT READ', $not_read],
		  ['READ', $read],
		  ['READ + CLICK', $click],
		  ['READ + UNSUB.', $unsub]
                ]
            }]
        });
 });
        
</script>

EOH
 
 return $html;
}


sub get_stats_clicks
{
 my $dbh = $_[0];
 my $dbh_mailer = $_[1];
 my $id_mailing = $_[2];
 my $id_sending = $_[3];
 my %sending = %{$_[4]};
 my %sending_ext = %{$_[5]};

 my @clicks = get_table($dbh_mailer,"stats","count(*) as cnt,params as url","op='click' and id_mailing=$sending_ext{id} GROUP BY params");
 
 my $read = $sending{nb_view};
 
 my $total_clicks = 0;
 my $t = "";
 my @djs1 = ();
 my @djs2 = ();

 my $cpt = 1;
 
 foreach my $click (@clicks) {

 my $link = "LINK #$cpt";
 $t .= <<"EOH";
<tr>
 <td class="stat_title">LINK #$cpt</td>
 <td class="stat_title"><a href="$click->{url}" target="_blank">$click->{url}</a></td>
 <td class="stat_data">$click->{cnt}</td></tr>
EOH

 push @djs1, "'$link'";
 push @djs2, $click->{cnt};

 $total_clicks+=$click->{cnt};
 $cpt++;
 }
 
 my $not_clicked = $read - $total_clicks;

 unshift @djs1,"'NO CLICK'";
 unshift @djs2,$not_clicked;
  
 my $djs1 = join(",",@djs1);
 my $djs2 = join(",",@djs2);
  
my $html = <<"EOH";
 
  <div class="stat_tab2">
  <table>
  <tr><td class="stat_title"> - </td><td class="stat_title">NO CLICK</td><td class="stat_data">$not_clicked</td></tr>
  $t
  </table>
</div><div id="stat_graph_clicks" class="graph_gfx2"></div>


<script type="text/javascript">

 \$(document).ready(function() {
 
\$('#stat_graph_clicks').highcharts({
            chart: {
                type: 'column',
//                margin: [ 50, 50, 100, 80]
                margin: [ 50, 50, 50, 80]
            },
            title: {
                text: 'Links'
            },
            xAxis: {
                categories: [
                $djs1
                ],
                labels: {
                    rotation: -45,
                    align: 'right',
                    style: {
                        fontSize: '13px',
                        fontFamily: 'Verdana, sans-serif'
                    }
                }
            },
            yAxis: {
                min: 0,
                title: {
                    text: 'Clicks'
                }
            },
            legend: {
                enabled: false
            },
        
            series: [{
                name: 'Clicks',
                data: [$djs2],
                dataLabels: {
                    enabled: true,
                    rotation: -90,
                    color: '#FFFFFF',
                    align: 'right',
                    x: 4,
                    y: 10,
                    style: {
                        fontSize: '13px',
                        fontFamily: 'Verdana, sans-serif'
                    }
                }
            }]
        });

    
    
     });
        
</script>
EOH
 
 return $html;
}


sub get_stats_timeline
{
 my $dbh = $_[0];
 my $dbh_mailer = $_[1];
 my $id_mailing = $_[2];
 my $id_sending = $_[3];
 my %sending = %{$_[4]};
 my %sending_ext = %{$_[5]};


 my @dates = ();
 for (my $i = 0; $i < 10; $i++) {
      my %d = select_table($dbh,"config","DATE_ADD(DATE('$sending_ext{queued_time}'), INTERVAL $i DAY) as zedate");
      push @dates,$d{zedate};
 }

  
 my $cpt = 0;
 my $t = "";
 my $nodate = 0;
 foreach my $date (@dates) {

     my %read = select_table($dbh_mailer,"stats","count(*) as cnt","op='open' and id_mailing=$sending_ext{id} AND DATE(moment) = '$date' GROUP BY DATE(moment)");
     my %err = select_table($dbh_mailer,"queue","count(*) as cnt","has_error='y' and id_mailing=$sending_ext{id} AND DATE(queued_on) = '$date' GROUP BY DATE(queued_on)",'','','',0);
     my %unsub = select_table($dbh,"mailing_blacklist","count(*) as cnt","reason='unsubscribe' and id_sending=$id_sending  AND DATE(moment) = '$date' GROUP BY DATE(moment)",'','','',0);
     if (!$unsub{cnt} && !$nodate) {
         %unsub = select_table($dbh,"mailing_blacklist","count(*) as cnt","reason='unsubscribe' and id_sending=$id_sending AND DATE(moment) = '0000-00-00' GROUP BY DATE(moment)",'','','',0);
         $nodate = 1;
     }


     my $nb_read = $read{cnt} || 0;
     my $nb_err = $err{cnt} || 0;
     my $nb_unsub = $unsub{cnt} || 0;

     $nb_read -= $nb_unsub;

     $t .= <<"EOH";
  <tr>
   <td class="stat_title">$date (D + $cpt)</td>
   <td class="stat_data">$nb_read</td>
   <td class="stat_data">$nb_unsub</td>
   <td class="stat_data">$nb_err</td>
   
   </tr>
EOH

    push @t_read,$nb_read;
    push @t_err,$nb_err;
    push @t_unsub,$nb_unsub;
      $cpt++;
 
 }



 my $jsd_read = join(",",@t_read);
 my $jsd_err = join(",",@t_err);
 my $jsd_unsub = join(",",@t_unsub);
 my $jsd_dates = join("','",@dates);
  
my $html = <<"EOH";
 
  <div class="stat_tab">
  <table>
  <tr><th> DATE </th><th> READ </th><th> UNSUB. </th><th> ERROR </th></tr>
$t
  </table>
</div><div id="stat_graph_timeline" class="graph_gfx"></div>


<script type="text/javascript">

 \$(document).ready(function() {
 
\$('#stat_graph_timeline').highcharts({
            chart: {
                type: 'bar'
            },
            title: {
                text: 'Timeline'
            },
            xAxis: {
                categories: ['$jsd_dates']
            },
            yAxis: {
                min: 0,
                title: {
                    text: 'mailing actions in time'
                }
            },
            legend: {
                backgroundColor: '#FFFFFF',
                reversed: true
            },
            plotOptions: {
                series: {
                    stacking: 'normal'
                }
            },
                series: [{
                name: 'READ',
                data: [$jsd_read]
            }, {
                name: 'UNSUBSCRIBE',
                data: [$jsd_unsub]
            }, {
                name: 'ERROR',
                data: [$jsd_err]
            }]
        });

    
    
     });
        
</script>
EOH
 
 return $html;
}


