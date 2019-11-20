#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use members;
use def_handmade;
use dm;
use mailing;

$dm_cfg{hide_prefixe} = 'y';
$dm_cfg{enable_search} = 1;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{tree} = 0;
$dm_cfg{operations} = 1;
$dm_cfg{excel} = 1;
$dm_cfg{corbeille} = 0;
$dm_cfg{search_save} = 1;
$dm_cfg{restauration} = 0;
$dm_cfg{autocreation} = 1;
$dm_cfg{excel_key} = 'id';
$dm_cfg{show_tab_in_toggle_form} = 'y';
# $dm_cfg{custom_filter_func}=\&extra_filter;
$dm_cfg{include_maps} = 1;


my $variable_col = " col-md-6 ";
$dm_cfg{default_ordby}= 'email';

my $tags_preview_container = get_quoted('tags_preview_container');
my $click_depuis = get_quoted('click_depuis');
my $ouvert_depuis = get_quoted('ouvert_depuis');

my $checked_ajout_pas_recu_cette_nl = '';
my $checked_ajout_pas_recu_aucune_nl = '';


my $list_tags_vals = get_quoted('list_tags_vals');
my $ajout_pas_recu_cette_nl = get_quoted('ajout_pas_recu_cette_nl');
if($ajout_pas_recu_cette_nl eq 'y')
{
	$checked_ajout_pas_recu_cette_nl = ' checked="checked" ';
}
my $ajout_pas_recu_aucune_nl = get_quoted('ajout_pas_recu_aucune_nl');
if($ajout_pas_recu_aucune_nl eq 'y')
{
	$checked_ajout_pas_recu_aucune_nl = ' checked="checked" ';
}
my $id_migcms_page = get_quoted('id_migcms_page');

# my $where = mailing::mailing_get_where_member({tags=>$mailing_sending{tags},num_optout=>$num_optout,click_depuis=>$mailing_sending{click_depuis},ouvert_depuis=>$mailing_sending{ouvert_depuis},ajout_pas_recu_cette_nl=>$mailing_sending{ajout_pas_recu_cette_nl},ajout_pas_recu_aucune_nl=>$mailing_sending{ajout_pas_recu_aucune_nl},id_migcms_page=>$mailing_sending{id_migcms_page}});
my $where = mailing::mailing_get_where_member({
tags=>$list_tags_vals,
num_optout=>1,
click_depuis=>$click_depuis,
ouvert_depuis=>$ouvert_depuis,
ajout_pas_recu_cette_nl=>$ajout_pas_recu_cette_nl,
ajout_pas_recu_aucune_nl=>$ajout_pas_recu_aucune_nl,
id_migcms_page=>$id_migcms_page});

$dm_cfg{wherep} = $where;
$dm_cfg{groupby} = "email";



$dm_cfg{table_name} = "migcms_members";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";

$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_prepare_mailing.pl?sel=".get_quoted('sel');


$dm_cfg{tag_search} = 1;
$dm_cfg{tag_table} = 'migcms_members_tags';
$dm_cfg{tag_col} = 'tags';

$dm_cfg{excel_key} ='id';

my $sel = get_quoted('sel');

%email_optin = 
(
	'01/y' =>"Oui",
	'02/n' =>"Non",
);
	
	my $tab = '';
	my $cpt = 9;
	%dm_dfl = 
	(    
		
		
		sprintf("%05d", $cpt++).'/email'			=>{'title'=>'Email','fieldtype'=>'text','data_type'=>'email','search' => 'y','mandatory'=>{"type" => ''},'tab'=>$tab='Acces','default_value'=>'','lbtable'=>'','lbkey'=>'','lbdisplay'=>'','lbwhere'=>'','fieldvalues'=>'','hidden'=>0},
		sprintf("%05d", $cpt++).'/email_optin'		=>{'title'=>'Optin email','fieldtype'=>'listbox','data_type'=>'button','search' => 'n','mandatory'=>{"type" => ''},'tab'=>$tab,'default_value'=>'n','lbtable'=>'','lbkey'=>'','lbdisplay'=>'','lbwhere'=>'','fieldvalues'=>\%email_optin,'hidden'=>0},   
	);
	
  
%dm_display_fields = 
(
 "04/Email"=>"email",
 # "05/Email optin"=>"email_optin",
);



%dm_lnk_fields = 
(
);

%dm_mapping_list = 
(
);

%dm_filters = 
(
  # "6/Email optin"=>
  # {
		      # 'type'=>'hash',
	     # 'ref'=>\%email_optin,
	     # 'col'=>'email_optin'
  # }
	
	
);
	my $list_mailings = get_sql_listbox({with_blank=>'n',selected_id=>$id_migcms_page,col_display=>"id",table=>"migcms_pages",where=>" migcms_pages_type = 'newsletter'",ordby=>"id",name=>'id_migcms_page',class=>""});

	$dm_cfg{list_html_top} .= <<"EOH";


<form method="GET" action="">
<input type="hidden" name="sel" value="$sel" />
	
<h3>Apercu des destinataires selon les règles:</h3>

<ol>
	<li>L'email est complété et valide</li>
	<li>L'email n'est pas dans la blacklist</li>
	<li>L'email a le statut optin à Oui</li>
	<li>Répond à l'ensemble des tags sélectionnés: 
	
	<a class="btn btn-default search_element openmodal get_toggle_tags_form_openmodal" data-toggle="modal" data-target="#get_toggle_tags_form" data-original-title="" title=""><i class="fa fa-tags" data-original-title="" title=""></i> Filter par tags </a>
	<input type="hidden" placeholder="" id="list_tags_vals" name="list_tags_vals" value="$list_tags_vals">
	<span class="tags_preview_container">$list_tags_vals</span>
	</li>
	<li>Répond aux règles spéciales ci-dessous:</li>
</ol>
<br />

	<div class="well">
	


	<div class="form-group item  row_edit_ajout_pas_recu_cette_nl  migcms_group_data_type_ hidden_0 ">
					
					<div class="col-sm-12 mig_cms_value_col">
						<label><input type="checkbox" id="field_ajout_pas_recu_cette_nl" name="ajout_pas_recu_cette_nl" $checked_ajout_pas_recu_cette_nl class=" cbsaveme" value="y"> Inclure les adresses emails de ceux qui n'ont pas reçu <b>cette</b> newsletter:</label>
						$list_mailings
						<span class="help-block text-left"></span>
					</div>

		</div>
		
		<br />
		<br />
		
		
	<div class="form-group item  row_edit_ajout_pas_recu_aucune_nl  migcms_group_data_type_ hidden_0 ">
					
				<div class="col-sm-12 mig_cms_value_col">
					<label>		
		
		<br /><input type="checkbox" id="field_ajout_pas_recu_aucune_nl" data-ordby="00540" name="ajout_pas_recu_aucune_nl" $checked_ajout_pas_recu_aucune_nl class=" cbsaveme" value="y"> Inclure les adresses emails de ceux qui n'ont reçu <b>aucune</b> newsletter.</label>

					<span class="help-block text-left"></span>
				</div>

</div>	
				

	
				
		<br />
		<br />
		<br />
		

<div class="form-group item  row_edit_ouvert_depuis  migcms_group_data_type_date hidden_0 ">


					Inclure les adresses emails de ceux qui ont ouvert depuis...  
	<input autocomplete="off" data-ordby="00560" type="text" data-domask="" name="ouvert_depuis" value="$ouvert_depuis" id="field_ouvert_depuis" class="form-control saveme saveme_txt add_datepicker" placeholder="">







					Inclure les adresses emails de ceux qui ont cliqués depuis...  
		
	
	<input autocomplete="off" data-ordby="00580" type="text" data-domask="" name="click_depuis" value="$click_depuis" id="field_click_depuis" class="form-control saveme saveme_txt add_datepicker" placeholder="">
					
			
</div>


		
		
		
		
		
		
		
		
	</div>

	

 <button type="submit" class="btn btn-success">OK</button>
</form> 
	<br /><br /><div class="hide">$where</div>
	
	
	
	<style>
	
	</style>
	<script>
	jQuery(document).ready(function() 
	{
	});
	</script>
EOH



$sw = $cgi->param('sw') || "list";
$sel = $cgi->param('sel') || "";
 see();
 

my @fcts = qw(
			add_form
			mod_form
			list
			add_db
			mod_db
			del_db
		);
		
		my $map_class = 'btn-default';
		my $search_all_class = 'btn-default';
		my $map_value = 'y';
		my $search_all_value = 'y';
		if(get_quoted('show_map') eq 'y')
		{
			$map_class='btn-primary';
			$map_value = 'n';
		}



my $style_et_js = <<"EOH";
<style>

</style>
<script type="text/javascript">
	
</script>
EOH

$dm_cfg{list_html_top} .= $style_et_js;
		
if (is_in(@fcts,$sw)) 
{ 
    dm_init();
	
	
    &$sw();

    if ($sw eq "list") {$spec_bar.=$lnkxls;}
    $migc_output{content} .= $dm_output{content};
    $migc_output{title} = $dm_output{title}.$migc_output{title};
    
    print migc_app_layout($migc_output{content},$migc_output{title},"",$gen_bar,$spec_bar);
}


