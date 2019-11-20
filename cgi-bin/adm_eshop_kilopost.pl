#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;

$dm_cfg{customtitle} = '';
$dm_cfg{table_name} = "shop_delcost_zones";
my $self="$config{baseurl}/cgi-bin/adm_eshop_kilopost.pl?";
%dm_dfl = (
    	);

%dm_display_fields = (
		);

%dm_lnk_fields = (
		);

%dm_mapping_list = (
);

%dm_filters = (
		);



$sw = $cgi->param('sw') || "list";

see();

my @fcts = qw(
			list
      save_zone 
		);

if (is_in(@fcts,$sw)) 
{ 
    dm_init();
    &$sw();
    $gen_bar = get_gen_buttonbar();
    $spec_bar = get_spec_buttonbar($sw);
    
   
  if($sw eq "list")
  {
    print wfw_app_layout($suppl_js.$dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
  }
  
}

sub move_all_countries
{
    see();
    my $dc_id_zone = get_quoted('dc_id_zone');
    my @countries=get_table($dbh,"countries","id,iso,en as name","iso NOT IN ( select isocode from shop_delcost_countries) order by name",'','','',0);
    for($i=0;$i<$#countries+1;$i++)
    {
        print "<br />add_country( $countries[$i]{iso} , $dc_id_zone );";
        add_country($countries[$i]{iso},$dc_id_zone);
    }
}

sub get_available_countries
{
      my $list='<ul class="dc_countries_list">';
      my @countries=get_table($dbh,"countries","id,iso,en as name","iso NOT IN ( select isocode from shop_delcost_countries) order by name",'','','',0);
      for($i=0;$i<$#countries+1;$i++)
      {
         my $url='';
         if( -e "../mig_skin/gfx/flags/$countries[$i]{iso}.gif")
         {
            $url="../mig_skin/gfx/flags/$countries[$i]{iso}.gif";
         }
         elsif(-e "../mig_skin/gfx/flags/$countries[$i]{iso}.png")
         {
            $url="mig_skin/gfx/flags/$countries[$i]{iso}.png";
         }
         elsif(-e "../mig_skin/gfx/flags/$countries[$i]{iso}.jpg")
         {
            $url="mig_skin/gfx/flags/$countries[$i]{iso}.jpg";
         }
         elsif(-e "../mig_skin/gfx/flags/$countries[$i]{iso}.jpg")
         {
            $url="#";
         }
         
         $list.=<<"EOH";
         
            <li>
              <a href="#" class="dc_add_country" id="$countries[$i]{iso}" title="Ajouter ce pays à la zone en cours"><img src="../mig_skin/gfx/dc_add.png" /></a>
              <img src="$url" style="width:18px" /> $countries[$i]{name}
              
            </li>
                    
EOH
      }
      $list.='</ul><inpyt type="hidden" class="header-actions" />';
      print $list;
      exit;
}

sub get_zones
{
      my $list='<ul class="dc_zones_list">';
      my @list=get_table($dbh,"shop_delcost_zones","id,name","1 order by id",'','','',0);
      for($i=0;$i<$#list+1;$i++)
      {
         my %total=select_table($dbh,"shop_delcost_countries","count(isocode) as nb","id_zone='$list[$i]{id}'",'','','',0);
         $list.=<<"EOH";
            <li><a href="#" class="dc_pick_zone dc_pick_zone_$list[$i]{id}" id="$list[$i]{id}">$list[$i]{name}</a> ($total{nb}) <a id="$list[$i]{id}" class="dc_delete_zone" href="#"><img src="../mig_skin/gfx/delete.png"></a></li>      
EOH
      }
      $list.='</ul>';
      print $list;
      exit;
}

sub add_country
{
     my $iso=get_quoted('iso') || $_[0];
     my $id_zone=get_quoted('id_zone') || $_[1];
     my %country=select_table($dbh,"countries","","iso='$iso'");
     see();
     
     my $stmt = "DELETE FROM shop_delcost_countries WHERE isocode = '$iso'";
     execstmt($dbh,$stmt); 
     if($id_zone > 0)
     {
         my %record=();
         $record{isocode}=$iso;
         $record{country_fr}=$country{en};
         $record{country_fr} =~ s/\'/\\\'/g;
         $record{id_zone}=$id_zone;
         inserth_db($dbh,'shop_delcost_countries',\%record); 
     }
     print 'ok';
}

sub delete_zone
{
    my $id_zone=get_quoted('id_zone');
    my $stmt = "DELETE FROM shop_delcost_countries WHERE id_zone = '$id_zone'";
    execstmt($dbh,$stmt);

    my $stmt = "DELETE FROM shop_delcost_zones_costs WHERE id_zone = '$id_zone'";
    execstmt($dbh,$stmt);

    my $stmt = "DELETE FROM shop_delcost_zones WHERE id = '$id_zone'";
    execstmt($dbh,$stmt);
    
    print "ok";
}

sub remove_country
{
     my $iso=get_quoted('iso');
     see();
     
     my $stmt = "DELETE FROM shop_delcost_countries WHERE isocode = '$iso'";
     execstmt($dbh,$stmt); 
     
     print 'ok';
}

sub get_this_zone
{
      my $id_zone=get_quoted('id_zone');
      my %zone=select_table($dbh,"shop_delcost_zones","","id='$id_zone'");
      
       #COUTS (PRIX)************************************************************
      my @costs=get_table($dbh,"shop_delcost_zones_costs","","id_zone='$id_zone' AND type ='prix' order by de",'','','',0);
      my $dc_iteration_prix=$#costs + 1;
      for($i=0;$i<$#costs+1;$i++)
      {
         $list_prix.=<<"EOH";
         
         <tr> 
            <td>
                <input type="text" value="$costs[$i]{de}" class="dc_zone_couts_prix_field_de_$i" name="dc_zone_couts_prix_field_de_$i" /> &euro;
            </td>
             <td>
                <input type="text" value="$costs[$i]{a}" class="dc_zone_couts_prix_field_a_$i" name="dc_zone_couts_prix_field_a_$i" /> &euro;
            </td>
            <td>
                <input type="text" value="$costs[$i]{price}" value="" class="dc_zone_couts_prix_field_cout_$i" name="dc_zone_couts_prix_field_cout_$i" /> &euro;
            </td>
        </tr>
EOH
      }
      
      
       #COUTS (QTY)************************************************************
      my @costs=get_table($dbh,"shop_delcost_zones_costs","","id_zone='$id_zone' AND type ='qty' order by de",'','','',0);
      my $dc_iteration_qty=$#costs + 1;
      for($i=0;$i<$#costs+1;$i++)
      {
         $list_qty.=<<"EOH";
         
         <tr> 
            <td>
                <input type="text" value="$costs[$i]{de}" class="dc_zone_couts_qty_field_de_$i" name="dc_zone_couts_qty_field_de_$i" /> unité(s)
            </td>
            <td>
                <input type="text" value="$costs[$i]{a}" class="dc_zone_couts_qty_field_a_$i" name="dc_zone_couts_qty_field_a_$i" /> unité(s)
            </td>
            <td>
                <input type="text" value="$costs[$i]{price}" value="" class="dc_zone_couts_qty_field_cout_$i" name="dc_zone_couts_qty_field_cout_$i" /> &euro;
            </td>
        </tr>
EOH
      }
                
                          
      #COUTS (POIDS)************************************************************
      my @costs=get_table($dbh,"shop_delcost_zones_costs","","id_zone='$id_zone' AND (type ='poids' OR type = '') order by de",'','','',0);
      my $dc_iteration_poids=$#costs + 1;
      for($i=0;$i<$#costs+1;$i++)
      {
         $list_poids.=<<"EOH";
         
         <tr> 
            <td>
                <input type="text" value="$costs[$i]{de}" class="dc_zone_couts_poids_field_de_$i" name="dc_zone_couts_poids_field_de_$i" /> Kg
            </td>
            <td>
                <input type="text" value="$costs[$i]{a}" class="dc_zone_couts_poids_field_a_$i" name="dc_zone_couts_poids_field_a_$i" /> Kg
            </td>
            <td>
                <input type="text" value="$costs[$i]{price}" value="" class="dc_zone_couts_poids_field_cout_$i" name="dc_zone_couts_poids_field_cout_$i" /> &euro;
            </td>
        </tr>
EOH
      }
     
      
      
      #PAYS ASSOCIES************************************************************
      my @countries=get_table($dbh,"shop_delcost_countries","","id_zone='$id_zone' order by country_fr",'','','',0);
      my $list_countries='';
      for($i=0;$i<$#countries+1;$i++)
      {
         my $url='';
         if(-e "../mig_skin/gfx/flags/$countries[$i]{isocode}.gif")
         {
            $url="mig_skin/gfx/flags/$countries[$i]{isocode}.gif";
         }
         elsif(-e "../mig_skin/gfx/flags/$countries[$i]{isocode}.png")
         {
            $url="mig_skin/gfx/flags/$countries[$i]{isocode}.png";
         }
         elsif(-e "../mig_skin/gfx/flags/$countries[$i]{isocode}.jpg")
         {
            $url="mig_skin/gfx/flags/$countries[$i]{isocode}.jpg";
         }
         elsif(-e "../mig_skin/gfx/flags/$countries[$i]{isocode}.jpg")
         {
            $url="#";
         }
         
         $list_countries .= <<"EOH";
            <li>
                <img src="$url" style="width:18px"/> $countries[$i]{country_fr}
                <a href="#" class="dc_remove_country" title="Retirer ce pays de la zone en cours" id="$countries[$i]{isocode}"><img src="../mig_skin/gfx/dc_remove.png" /></a>
            </li> 
EOH
      }
      
#       my $list_coupons = '<select name="id_coupon" class="id_coupon">';
#       my @coupons = sql_lines({table=>'eshop_coupons',ordby=>'coupons'});
#       foreach $coupon(@coupons)
#       {
#           my %coupon = %{$coupon};
#           my $selected = '';
#           if($coupon{id} == $zone{id_coupon})
#           {
#               $selected = 'selected="selected"';
#           }
#           $list_coupons .=<< "EOH";
#               <option $selected value="$coupon{id}">$coupon{coupons}</option>
# EOH
#       }
#       $list_coupons .= '</select>';
      
      
      
      my $resultat=<<"EOH";
      <h1>Zone: <input type="text" value="$zone{name}" name="dc_zone_name" /></h1>
      <input type="hidden" name="dc_id_zone"  class="dc_id_zone" value="$zone{id}" />
      
      <input type="hidden" name="dc_iteration_prix" class="dc_iteration_prix" value="$dc_iteration_prix" />
      <input type="hidden" name="dc_iteration_qty" class="dc_iteration_qty" value="$dc_iteration_qty" />
      <input type="hidden" name="dc_iteration_poids" class="dc_iteration_poids" value="$dc_iteration_poids" />
            <br /><br />   <h2>Pays associés à cette zone</h2>
     
       
       <ul>
       
       $list_countries
       
       </ul>
          <br />
           Gratuit à partir de: <input type="text" value="$zone{free_after}" name="dc_zone_free_after" class="dc_zone_free_after" /> €
           <!--<br /><br />
           OU
           <br /><br /> 
           Gratuit avec le coupon: $list_coupons
           -->  
           <br /><br /> 
         
          
          
          
     <h2>1. Couts de livraison par rapport au prix</h2>
      <br /><br />
     <a href="#" class="dc_add_cost_prix">Ajouter un cout</a>  
      <br /><br />
     
     <table class="dc_zone_couts_prix_table_ligne_a_cloner" style="display:none;">
        <tr> 
            <td>
                <input type="text" value="" class="dc_zone_couts_prix_field_de_ITERATION_PRIX" name="dc_zone_couts_prix_field_de_ITERATION_PRIX" /> &euro;
            </td>
            <td>
                <input type="text" value="" class="dc_zone_couts_prix_field_a_ITERATION_PRIX" name="dc_zone_couts_prix_field_a_ITERATION_PRIX" /> &euro;
            </td>
            <td>
                <input type="text" value="" class="dc_zone_couts_prix_field_cout_ITERATION_PRIX" name="dc_zone_couts_prix_field_cout_ITERATION_PRIX" /> &euro;
            </td>
        </tr>
     </table>
      
      <table class="dc_zone_couts_table_prix">
      <tr>
          <th>
             De
          </th>
          <th>
             à
          </th>
          <th>
              Coût
          </th>
      </tr>
      
      $list_prix
      
      </table>
      
      
      
      
      
      
      
      
      
      <h2>2. Couts de livraison par rapport à la quantité commandée</h2>
      <br /><br />
     <a href="#" class="dc_add_cost_qty">Ajouter un cout</a>  
      <br /><br />
     
     <table class="dc_zone_couts_qty_table_ligne_a_cloner" style="display:none;">
        <tr> 
            <td>
                <input type="text" value="" class="dc_zone_couts_qty_field_de_ITERATION_QTY" name="dc_zone_couts_qty_field_de_ITERATION_QTY" /> unité(s)
            </td>
            <td>
                <input type="text" value="" class="dc_zone_couts_qty_field_a_ITERATION_QTY" name="dc_zone_couts_qty_field_a_ITERATION_QTY" /> unité(s)
            </td>
            <td>
                <input type="text" value="" class="dc_zone_couts_qty_field_cout_ITERATION_QTY" name="dc_zone_couts_qty_field_cout_ITERATION_QTY" /> &euro;
            </td>
        </tr>
     </table>
      
      <table class="dc_zone_couts_table_qty">
      <tr>
           <th>
             De
          </th>
          <th>
             à
          </th>
          <th>
              Coût
          </th>
      </tr>
      
      $list_qty
      
      </table>
      
      
      
      
      
      
      
      
      
      
           <h2>3. Couts de livraison par rapport au poids</h2>
      <br /><br />
     <a href="#" class="dc_add_cost_poids">Ajouter un cout</a>  
      <br /><br />
     
     <table class="dc_zone_couts_poids_table_ligne_a_cloner" style="display:none;">
        <tr> 
            <td>
                <input type="text" value="" class="dc_zone_couts_poids_field_de_ITERATION_POIDS" name="dc_zone_couts_poids_field_de_ITERATION_POIDS" /> Kg
            </td>
            <td>
                <input type="text" value="" class="dc_zone_couts_poids_field_a_ITERATION_POIDS" name="dc_zone_couts_poids_field_a_ITERATION_POIDS" /> Kg
            </td>
            <td>
                <input type="text" value="" class="dc_zone_couts_poids_field_cout_ITERATION_POIDS" name="dc_zone_couts_poids_field_cout_ITERATION_POIDS" /> &euro;
            </td>
        </tr>
     </table>
      
      <table class="dc_zone_couts_table_poids">
      <tr>
           <th>
             De
          </th>
          <th>
             à
          </th>
          <th>
              Coût
          </th>
      </tr>
      
      $list_poids
      
      </table> 
      
      
      
      
      
      
      
      
      
      
              <br /><br />  
        <button class="mig_button" id="dc_save_zone" style="clear:both;" type="submit">Sauver</button>
             <br /><br />  
       <br /><br />
      
       <br /><br />
EOH
      print $resultat;
      exit;
}

sub save_zone
{
#     see();
    
    #ZONE***********************************************************************
    my %zone=();
    $zone{name}=get_quoted('dc_zone_name');
    $zone{free_after}=get_quoted('dc_zone_free_after');
    $zone{id_coupon} = get_quoted('id_coupon');
    my $id_zone=get_quoted('dc_id_zone');
    if($id_zone > 0)
    {
        updateh_db($dbh,'shop_delcost_zones',\%zone,"id",$id_zone);
    }
    else
    {
         $id_zone=inserth_db($dbh,'shop_delcost_zones',\%zone);
    }
     
    #ZONE COSTS*****************************************************************
    my $stmt = "DELETE FROM shop_delcost_zones_costs WHERE id_zone = '$id_zone'";
    execstmt($dbh,$stmt); 
    
    my $dc_iteration_poids=get_quoted('dc_iteration_poids') || 0;
    my $dc_iteration_prix=get_quoted('dc_iteration_prix') || 0;
    my $dc_iteration_qty=get_quoted('dc_iteration_qty') || 0;
    
    for($z=0;$z<$dc_iteration_poids;$z++)
    {  
        my %zone_costs=();
        $zone_costs{id_zone}=$id_zone;
        $zone_costs{de}=get_quoted('dc_zone_couts_poids_field_de_'.$z);
        $zone_costs{a}=get_quoted('dc_zone_couts_poids_field_a_'.$z);
        $zone_costs{price}=get_quoted('dc_zone_couts_poids_field_cout_'.$z);
        $zone_costs{type}='poids'; 
        if($zone_costs{de} ne '' && $zone_costs{a} ne '' && $zone_costs{price}  ne '')
        {
            inserth_db($dbh,'shop_delcost_zones_costs',\%zone_costs);
        }  
    }
    for($z=0;$z<$dc_iteration_prix;$z++)
    {  
        my %zone_costs=();
        $zone_costs{id_zone}=$id_zone;
        $zone_costs{de}=get_quoted('dc_zone_couts_prix_field_de_'.$z);
        $zone_costs{a}=get_quoted('dc_zone_couts_prix_field_a_'.$z);
        $zone_costs{price}=get_quoted('dc_zone_couts_prix_field_cout_'.$z);
        $zone_costs{type}='prix';
        if($zone_costs{de} ne '' && $zone_costs{a} ne '' && $zone_costs{price} ne '')
        {
            inserth_db($dbh,'shop_delcost_zones_costs',\%zone_costs);
        }  
    }
    for($z=0;$z<$dc_iteration_qty;$z++)
    {  
        my %zone_costs=();
        $zone_costs{id_zone}=$id_zone;
        $zone_costs{de}=get_quoted('dc_zone_couts_qty_field_de_'.$z);
        $zone_costs{a}=get_quoted('dc_zone_couts_qty_field_a_'.$z);
        $zone_costs{price}=get_quoted('dc_zone_couts_qty_field_cout_'.$z);
        $zone_costs{type}='qty';
        if($zone_costs{de} ne '' && $zone_costs{a} ne '' && $zone_costs{price} ne '')
        {
            inserth_db($dbh,'shop_delcost_zones_costs',\%zone_costs);
        }  
    }
    http_redirect("$self&sw=list&id_zone=$id_zone");   
    exit;
}

sub list
{
    my $id_zone=get_quoted('id_zone') || '';
    my $page=<<"EOH";
    <script type="text/javascript">
        jQuery(document).ready(function() 
        {
				load_available_countries();
                load_zones($id_zone);
                    
				jQuery(document).on("click", ".dc_pick_zone", dc_pick_zone);
				jQuery(document).on("click", "#dc_add_zone", add_zone);
				jQuery(document).on("click", ".dc_add_cost_qty", add_cost_qty);
				jQuery(document).on("click", ".dc_add_cost_prix", add_cost_prix);
				jQuery(document).on("click", ".dc_add_cost_poids", add_cost_poids);
				jQuery(document).on("click", ".dc_add_country", add_country);
				jQuery(document).on("click", ".dc_remove_country", remove_country);
				jQuery(document).on("click", "#dc_save_zone", save_zone);
				jQuery(document).on("click", ".dc_delete_zone", delete_zone);
				jQuery(document).on("click", ".move_all_countries", move_all_countries);              
        });
        
        function move_all_countries()
        {
            if(confirm('Désirez vous déplacer tous les produits dans la zone active ?'))
            {
                 var dc_id_zone = jQuery(".dc_id_zone").val();
                 jQuery.ajax(
                 {
                     type: "POST",
                     url: "$config{fullurl}/cgi-bin/adm_eshop_kilopost.pl",
                     data: "sw=move_all_countries&dc_id_zone="+dc_id_zone,
                     success: function(msg)
                     {
                           
                     }
                 });
            }
            return false;
        }
        
        
        function load_available_countries()
        {
            jQuery('.dc_box2_container').html('<img src="../mig_skin/gfx/ajax-loader.gif" />');
            jQuery.ajax(
            {
               type: "POST",
               url: "$config{fullurl}/cgi-bin/adm_eshop_kilopost.pl",
               data: "sw=get_available_countries",
               success: function(msg)
               {
                     jQuery('.dc_box2_container').html(msg);
               }
            });
        }
        
        function load_zones(default_id_zone)
        {
            jQuery('.dc_zones_container').html('<img src="../mig_skin/gfx/ajax-loader.gif" />');
            jQuery.ajax(
            {
               type: "POST",
               url: "$config{fullurl}/cgi-bin/adm_eshop_kilopost.pl",
               data: "sw=get_zones",
               success: function(msg)
               {
                     jQuery('.dc_zones_container').html(msg);
                     
                     if(default_id_zone > 0)
                     {
                        jQuery('.dc_pick_zone_'+default_id_zone).click();
                     }
                     else
                     {
                        jQuery('.dc_zones_container a:first').click();
                     }
               }
            });
        }
        
        function dc_pick_zone(id_zone_alt)
        {
            var id_zone=jQuery(this).attr('id');

            if(id_zone_alt > 0)
            {
                id_zone=id_zone_alt;
            }
            
            if(id_zone > 0)
            {
                jQuery("#dc_add_zone").show();
                jQuery(".dc_box2").show();
            }
            
            jQuery('.dc_box1_container').html('<img src="../mig_skin/gfx/ajax-loader.gif" />');
            jQuery.ajax(
            {
               type: "POST",
               url: "$config{fullurl}/cgi-bin/adm_eshop_kilopost.pl",
               data: "sw=get_this_zone&id_zone="+id_zone,
               success: function(msg)
               {
                     jQuery('.dc_box1_container').html(msg);
                     
                     jQuery('.dc_add_cost_qty').click();
                     jQuery('.dc_add_cost_poids').click();
                     jQuery('.dc_add_cost_prix').click();
               }
            });
            
            
            return false;
        }
        
        function add_country()
        {
            var iso=jQuery(this).attr('id');
            var id_zone=jQuery(".dc_id_zone").val();
            jQuery.ajax(
            {
               type: "POST",
               url: "$config{fullurl}/cgi-bin/adm_eshop_kilopost.pl",
               data: "sw=add_country&iso="+iso+"&id_zone="+id_zone,
               success: function(msg)
               {
                     load_available_countries();
                     dc_pick_zone(id_zone);
               }
            });
            return false;
        }
        
        function remove_country()
        {
            var iso=jQuery(this).attr('id');
            var id_zone=jQuery(".dc_id_zone").val();
            jQuery.ajax(
            {
               type: "POST",
               url: "$config{fullurl}/cgi-bin/adm_eshop_kilopost.pl",
               data: "sw=remove_country&iso="+iso,
               success: function(msg)
               {
                     load_available_countries();
                     dc_pick_zone(id_zone);
               }
            });
            
            return false;
        }
        
        function add_cost_qty()
        {
            var ligne_qty=jQuery('.dc_zone_couts_qty_table_ligne_a_cloner').html();
            var iteration_qty=jQuery('.dc_iteration_qty').val();
            var reg=new RegExp("ITERATION_QTY", "g");
            ligne_qty=ligne_qty.replace(reg,iteration_qty);
            iteration_qty++;
            jQuery('.dc_iteration_qty').val(iteration_qty);
            jQuery(".dc_zone_couts_table_qty").append(ligne_qty);
            return false;
        }
        
        function add_cost_poids()
        {
            var ligne_poids=jQuery('.dc_zone_couts_poids_table_ligne_a_cloner').html();
            var iteration_poids=jQuery('.dc_iteration_poids').val();
            var reg=new RegExp("ITERATION_POIDS", "g");
            ligne_poids=ligne_poids.replace(reg,iteration_poids);
            iteration_poids++;
            jQuery('.dc_iteration_poids').val(iteration_poids);
            jQuery(".dc_zone_couts_table_poids").append(ligne_poids);
            return false;
        }
        
        function add_cost_prix()
        {
            var ligne_prix=jQuery('.dc_zone_couts_prix_table_ligne_a_cloner').html();
            var iteration_prix=jQuery('.dc_iteration_prix').val();
            var reg=new RegExp("ITERATION_PRIX", "g");
            ligne_prix=ligne_prix.replace(reg,iteration_prix);
            iteration_prix++;
            jQuery('.dc_iteration_prix').val(iteration_prix);
            jQuery(".dc_zone_couts_table_prix").append(ligne_prix);
            return false;
        }
        
        function add_zone()
        {
            if(confirm('Désirez vous abandonner vos modifications et ajouter une nouvelle zone ?'))
            {
                jQuery("#dc_add_zone").hide();
                jQuery(".dc_box2").hide();
                
                dc_pick_zone(0);
            }
            return false;
        }
        
        function delete_zone()
        {
            if(confirm('Désirez vous supprimer cette zone ainsi que tous les couts et les associations aux pays ?'))
            {
               var id_zone=jQuery(this).attr('id');
               jQuery.ajax(
               {
                 type: "POST",
                 url: "$config{fullurl}/cgi-bin/adm_eshop_kilopost.pl",
                 data: "sw=delete_zone&id_zone="+id_zone,
                 success: function(msg)
                 {
                       load_available_countries();
                       load_zones();
                 }
               });
            }
            return false;
        }
        
        function save_zone()
        {
            jQuery(".dc_form_costs").submit();
            return false;
        }
        
    </script>
    
    
    
    <style>
    .dc_box
    {
        background-color:#efefef;
        float:left;
        border:1px solid #333333;

        overflow: auto;
        padding:10px;
        overflow:auto;
        height:800px;
    }
    .dc_box1
    {
        width:700px;
    }
    .dc_box2
    {
        width:300px;

    }
    li
    {
      list-style:none;
    }
    
    </style>
     
     <form method="post" action="$self" class="dc_form_costs">
      <input type="hidden" name="sw" value="save_zone" />

    <div class="dc_zones">
        <h1>Zones</h1>
        
        <br /><br />
        <a href="#" id="dc_add_zone">Ajouter une zone</a>
        <br /><br />        
        <span class="dc_zones_container">
      
        </span>
        
    </div>
          <br /><br />  
    
    <div class="dc_box dc_box1 ui-corner-all">
      <span class="dc_box1_container">
      
      
      
      
      </span> 
       
    </div>
    <div class="dc_box dc_box2 ui-corner-all">
     <h1>Pays non associés</h1>
     
      <br />
      <a href="#" class="move_all_countries">Tous</a>
      <br /><br />
      <span class="dc_box2_container">
      
      
      
      
      </span>
      
      
      
          
    </div>
    
    
        
     </form>
EOH


   $dm_output{content}=$page;
}


#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------