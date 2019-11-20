var self='';
var scrollbarposition = 0;

$(document).ready(function() 
{
	init();
	
    $(document).on("click", ".migedit", migedit);
	$(document).on("click", ".migadd", migadd);
	
	
    $(document).on("click", ".cancel_edit", cancel_edit);
    $(document).on("click", "#list_afficher_tout", list_refresh);
    $(document).on("submit", "#list_form_search", list_launch_search);
    $(document).on("click", "#list_search", list_launch_search);
    $(document).on("click", ".numpage", change_page);
    $(document).on("click", ".admin_list_pagination_begin", admin_list_pagination_begin);
    $(document).on("click", ".admin_list_pagination_previous", admin_list_pagination_previous);
    $(document).on("click", ".admin_list_pagination_next", admin_list_pagination_next);
    $(document).on("click", ".admin_list_pagination_end", admin_list_pagination_end);
    $(document).on("click", "#search_toggle", search_toggle);
    $(document).on("click", "#action_globale_delete", action_globale_delete);
	$(document).on("click", "#action_globale_corbeille", action_globale_corbeille);
	$(document).on("click", "#action_globale_restauration", action_globale_restauration);
	$(document).on("click", "#action_globale_pdfzip", action_globale_pdfzip);

	$(document).on("click", ".action_globale_custom", action_globale_custom);
    $(document).on("click", "#check_all_cb", check_all_cb);
    $(document).on("click", "#action_globale_show", action_globale_show);
    $(document).on("click", "#action_globale_hide", action_globale_hide);
    $(document).on("click", ".link_changevis", link_changevis);
  	$(document).on("click", ".edit_switch_language1", edit_switch_language1);
	$(document).on("click", ".edit_switch_language2", edit_switch_language2);
  	$(document).on("click", ".list_sort", list_sort);
  	$(document).on("click", ".close_sorting_box", clic_close_sorting_box);
  	$(document).on("click", ".save_sorting_box", clic_save_sorting_box);
  	$(document).on("click", "#sorting_box_first", sorting_box_first);
  	$(document).on("click", "#sorting_box_previous", sorting_box_previous);
  	$(document).on("click", "#sorting_box_next", sorting_box_next);
  	$(document).on("click", "#sorting_box_last", sorting_box_last);
  	$(document).on("click", ".list_delete", list_delete);
	$(document).on("click", ".list_corbeille", list_corbeille);
	$(document).on("click", ".list_restaurer", list_restaurer);

	$(document).on("click", ".return_to_list", return_to_list);
	$(document).on("change", ".parag_template", parag_template);
	$(document).on("click", ".list_autosavecb",list_autosavecb);
	$(document).on("click", "#export_excel",export_excel);
	$(document).on("click", "#export_txt",export_txt);
	$(document).on("keyup", "#list_keyword",live_search);
	
	$(document).on("click", ".operations_button",operations_button);
	$(document).on("click", ".dupliquer", dupliquer);
	$(document).on("click", ".lock_on", lock_on);
	$(document).on("click", ".lock_off", lock_off);
	$(document).on("click", ".viewpdf", viewpdf);
	$(document).on("click", ".telecharger", telecharger);
	$(document).on("click", ".send_by_email", send_by_email);
	$(document).on("click", "#restauration_switch", restauration_switch);
	$(document).on("click", ".nr_select", nr_select);

	$(document).on("keyup", "#id_textid_meta_title_page",seosimulatortitle);
	$(document).on("keyup", "#id_textid_meta_description_page",seosimulatordescription);
	
	 setInterval(check_session_validity, 30000);
	
	
	$(".se-pre-con").fadeOut("fast");
	
	$(".show_only_after_document_ready").removeAttr('disabled');
	var self = get_self('full');
	
	window.onbeforereload=before;
	window.onunload=after;
	
	var default_ordby = $("#default_ordby").val();
	if(default_ordby != '')
	{
		$("#"+default_ordby+'.sorting').children('.sorting_icon').html('<i class="fa fa-sort-asc"></i>');
		$("#"+default_ordby+'.sorting').removeClass('sorting').addClass('sorting_asc');
	}
	//history.replaceState({state: 'list'}, 'list',self);
	
	//$(".return_to_list").click();
	/*
	$.History.bind(function(state)
	{
		if(state == '/list')
		{ 
			
		}
    });
	*/
	
	window.onpopstate = function(event) 
	{
		
//		console.log("location: " + document.location + ", state: " + JSON.stringify(event.state));
		if(event != null && event.state != null)
		{
			var state = 'list';
			
			if(typeof event.state.state != 'undefined')
			{
				state = event.state.state;
			}
				
			var id_record = event.state.id_record;

	
			switch(state)
			{
				case 'list': show_list(); break;
				case 'ajout': show_add(); break;
				case 'edit': edit_record(id_record); break;
			}
		}
		else
		{
			show_list();
		}
	};
	
    init_add_form(); 
    init_nr(); 
});
  
   
function init_add_form()
{
	if($("#list_sw").val() == 'add')
	{
		mig_post_edit_form();
		$("#list_func").val('list_body_ajax');
	}
	if($("#list_sw").val() == 'mod')
	{
		mig_post_edit_form();
		$("#list_func").val('list_body_ajax');
	}
}
  
function list_sort()
{
		var id_rec = parseInt($(this).attr('id'));
        // if(!(id_rec > 0))
        // {
            // id_rec = parseInt($("#current_id_rec").val()); 
			
        // }
        
        // var new_ordby = $(".rec_"+id_rec+" .list_ordby").text();  
        var new_ordby =$(".ordby_number_"+id_rec).text(); 
		
		
        $("#new_ordby").val(new_ordby);
			
        $("#new_ordby_id").val(id_rec);
        repositionne_sorting_box(id_rec);
        $("#sorting_box").fadeIn();
		
        return false;
}   

function nr_select()
{
	$("#nr").val($(this).attr('id'));
	$(".nr_sel").html($(this).html());
	$("#page").val(1);
	get_list_body();
}

function repositionne_sorting_box(id_rec,top,left)
{
     // console.log('repositionne_sorting_box for '+id_rec);
     if(id_rec > 0)
     { 
		 var me = $(".list_sort_"+id_rec);
         if(!me.length)
         {
            me = $(".aclicker_"+id_rec);
         }
         line_highlight(id_rec);
         var position = me.offset();
          
         var x = parseInt(position.left) - 67;
         var y = parseInt(position.top) + 35;
		 		 
		 if($("#page_func").val() == 'list_pages')
		 {
		    var position_x = $(".notification-menu").offset();
			var position_y = $(".migedit_"+id_rec).parent().parent().offset();

			x = parseInt(position_x.left) ;
            y = parseInt(position_y.top) ;
		 }
		 		 
         $("#sorting_box").css('left',x+'px').css('top',y+'px');
         
           // console.log('e');
    }
    else
    {
      if(top > 0 && left > 0)
      {
         $("#sorting_box").css('left',top+'px').css('top',left+'px');
      }
    }
}
        

function change_ordby_db(new_ordby,id_rec)
{
    var request = $.ajax(
    {
        url: self,
        type: "GET",
        data: 
        {
           sw : 'list_change_ordby_db_ajax',
           new_ordby : new_ordby,
           id_rec : id_rec
        },
        dataType: "html"
    });
    
    request.done(function(msg) 
    {
	   get_list_body();
       
    });
    request.fail(function(jqXHR, textStatus) 
    {
        alert( "Erreur lors du changement d'ordre: " + textStatus );
    });
}

   
//INITIALISATIONS DIVERSES    
function init()
{
	init_google_map('disno_markers');

	// Création COOKIE pour le menu
	var cookieValue = $.cookie("mig_menu");
	if(cookieValue == undefined) {
		$.cookie("mig_menu", "", { expires: 365 });
	}
	
	if(cookieValue == "menu-collapsed") {
		jQuery('body').addClass('left-side-collapsed');
		jQuery('.custom-nav ul').attr('style','');
		jQuery(this).addClass('menu-collapsed');
	}
	
	// MENU MULTI NIVEAUX
	$("body:not(.left-side-collapsed) .menu-list > ul > li.has-sub-menu-list > a").click(function() {
		$(this).parent().children("ul").show();
		$(this).parent().parent().addClass("open");
		var slidemenu_height = $(this).parent().children('ul').height();
		//alert($(this).parent().children('ul').html());
		$(this).parent().parent().animate({'min-height':slidemenu_height,'margin-left':'-240px'}, 200);
		return false;
	});

	$(".menu-list > ul > li").find("button").click(function() {
		$(this).parent().parent().parent().parent().removeClass("open");
		$(this).parent().parent().parent().parent().animate({'min-height':'0px','margin-left':'0px'}, 200, function() {
			//$("body:not(.left-side-collapsed) .menu-list > ul > li.has-sub-menu-list > ul").hide();
			$(this).children().children("ul").hide();
		});
		return false;
	});

	$(".menu-list > ul > li.has-sub-menu-list > ul > li > ul > li.has-sub-menu-list > a").click(function() {
		if($(this).parent("li").hasClass("open")) {
			$(this).parent("li").removeClass("open").children("ul:first").removeClass("open").slideUp(200,function() {
				var slidemenu_height = $(this).parent().parent().parent().parent().height();
				$(this).parent().parent().parent().parent().parent().parent().css({'min-height':slidemenu_height});
			});
		}
		else {
			$(this).parent("li").addClass("open").children("ul:first").slideDown(200,function() {
				var slidemenu_height = $(this).parent().parent().parent().parent().height();
				$(this).parent().parent().parent().parent().parent().parent().css({'min-height':slidemenu_height});
			});
		}
		return false;
	});
	
	// SI NIVEAU 3 sélectionné
	var iflevel3 = $(".custom-nav").find("a.active.level3").html();
	if(iflevel3 != undefined) {
		$(".custom-nav").find("a.active.level3").parent().parent().parent().parent().show();
		$(".custom-nav").find("a.active.level3").parent().parent().parent().parent().parent().addClass("open");
		var slidemenu_height_lvl3 = $(".custom-nav").find("a.active.level3").parent().parent().parent().parent().height();
		$(".custom-nav").find("a.active.level3").parent().parent().parent().parent().parent().parent().css({'min-height':slidemenu_height_lvl3,'margin-left':'-240px'});
	}
	
	// SI NIVEAU 4 sélectionné
	var iflevel4 = $(".custom-nav").find("a.active.level4").html();
	if(iflevel4 != undefined) {
		$(".custom-nav").find("a.active.level4").parent().parent().show();
		$(".custom-nav").find("a.active.level4").parent().parent().parent().parent().show();
		$(".custom-nav").find("a.active.level4").parent().parent().parent().addClass("open");
		$(".custom-nav").find("a.active.level4").parent().parent().parent().parent().addClass("open");
		$(".custom-nav").find("a.active.level4").parent().parent().parent().parent().parent().parent().show();
		var slidemenu_height_lvl4 = $(".custom-nav").find("a.active.level4").parent().parent().parent().parent().parent().height();
		$(".custom-nav").find("a.active.level4").parent().parent().parent().parent().parent().parent().parent().parent().css({'min-height':slidemenu_height_lvl4,'margin-left':'-240px'});
	}	
	
	//HEADER FIXED
	headeractions();
	
	var nbr_checkbox = 0;
	//MASQUER
	var nbr_actions_globals = $("#btn-group-actions_globales a").length;
	if(nbr_actions_globals == 0) {
		$(".row_actions_globales").addClass("hide");
	}
	
    //définir self
    self = get_self('full');
    
    //cacher loader
    //$(".admin_list_pageloader").hide();
    
    re_init();
	initialiser_champs_speciaux();
   
    //sauvegarde form edit
    $(document).on('click', '.admin_edit_save', function(e) 
    {
        admin_save_form();
        e.preventDefault();
    });
	
	if($("#filters_set").val() == 1)
	{
		$(".panel-collapse").addClass('in');
		list_launch_search();
 	}

	$(".list_filter").change(function()
	{
		list_launch_search();
	});

	//init_valid_form('valid_form_add');
	
	$('.report_range').daterangepicker({
        format: 'DD/MM/YYYY',
        startDate: moment().subtract(29, 'days'),
        endDate: moment(),
        showDropdowns: true,
        showWeekNumbers: false,
        timePicker: false,
        timePickerIncrement: 1,
        timePicker12Hour: true,
        ranges: {
		   'M-1': [moment().subtract(1, 'month').startOf('month'), moment().subtract(1, 'month').endOf('month')],
		   'Ce mois': [moment().startOf('month'), moment().endOf('month')],
		   'Cette semaine': [moment().subtract(6, 'days'), moment()],
		   'Hier': [moment().subtract(1, 'days'), moment().subtract(1, 'days')],
		   "Aujourd'hui": [moment(), moment()],
		   'Demain': [moment().add(1, 'days'), moment().add(1, 'days')],
		   'M+1': [moment().add(1, 'month').startOf('month'), moment().add(1, 'month').endOf('month')],
        },
        opens: 'right',
        drops: 'down',
        buttonClasses: ['btn', 'btn-sm'],
        applyClass: 'btn-success',
        cancelClass: 'btn-danger',
        separator: ' au ',
        locale: {
            applyLabel: 'OK',
            cancelLabel: 'Annuler',
            fromLabel: 'Du',
            toLabel: 'Au',
            customRangeLabel: 'Interval personnalisé',
            daysOfWeek: ['Di', 'Lu', 'Ma', 'Me', 'Je', 'Ve','Sa'],
            monthNames: ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Aout', 'Septem', 'October', 'November', 'December'],
            firstDay: 1
        }
    }, function(start, end, label) {
        console.log(start.toISOString(), end.toISOString(), label);
        $('#reportrange span').html(start.format('MMMM D, YYYY') + ' - ' + end.format('MMMM D, YYYY'));
    });
	
	$(".report_range").change(function()
	{
		list_launch_search();
	});
	
	
	$.validatr.messages = {
    checkbox: 'Please check this box if you want to proceed.',
    color: 'Please enter a color in the format #xxxxxx',
    email: {
        single: 'Please enter an email address.',
        multiple: 'Please enter a comma separated list of email addresses.'
    },
    pattern: 'Please match the requested format.',
    radio: 'Please select one of these options.',
    range: {
        base: 'Please enter a {{type}}',
        overflow: 'Please enter a {{type}} greater than or equal to {{min}}.', 
        overUnder: 'Please enter a {{type}} greater than or equal to {{min}}<br> and less than or equal to {{max}}.',
        invalid: 'Invalid {{type}}',
        underflow: 'Please enter a {{type}} less than or equal to {{max}}.'
    },
    required: 'Please fill out this field.',
    select: 'Please select an item in the list.',
    time: 'Please enter a time in the format hh:mm:ss',
    url: 'Please enter a url.'
	};
	
	 //init valid form
	// $('.valid_form_add').validatr(); 
	
	 //applyautocomplete
	  $(".insert_autocomplete_txt").each(function(i)
	  {
		
			var url_autocomplete = $(this).attr('data-doautocomplete');
			var valeurs = new Bloodhound(
			{
				datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
				queryTokenizer: Bloodhound.tokenizers.whitespace,
				limit: 25,
				remote: url_autocomplete+'&query=%QUERY'
			});
			valeurs.initialize();
			
		
			
			$(this).typeahead(null, {
				name: 'desktopsearch',
				autoselect: false,
				displayKey: 'affichage',
				highlight :true,
				hint:false,
				source: valeurs.ttAdapter()
			});
			$(this).bind('typeahead:selected', function(obj, datum, name) 
			{   
				jQuery(this).val(datum.name);
			});
			$(this).bind('typeahead:opened', function(obj, datum, name) 
			{   
			});
			$(this).bind('typeahead:closed', function(obj, datum, name) 
			{   
			
			});
			$(this).bind('typeahead:autocompleted', function(obj, datum, name) 
			{   
				jQuery(this).val(datum.name);
			});
			jQuery(this).removeClass('autocomplete_txt');
		
	  });
	  
	  jQuery("#list_keyword").focus();  
	  
	    var custom_func = jQuery('#javascript_custom_func_form').val();
		if(custom_func == '')
		{
			custom_func = 'dum';
		}           
		if(typeof custom_func != 'undefined')
		{
			window[custom_func]();
		}
		
		
}

function init_google_map(action)
{
	if($("#googlemap").length)
	{
		var tab_markers = [];
		
		if(action != 'no_markers')
		{
			
			 var request = $.ajax(
			{
				url: self,
				type: "GET",
				data: 
				{
				   sw : 'google_map_markers',
				},
				dataType: "html"
			});
			
			request.done(function(msg) 
			{
			   $("#liste-points").html(msg);
			   var i = 0;
				$(".markers").each(function(){
					var tab_contenu = $(this).html().split("___");


					var lat = tab_contenu[0].substr(tab_contenu[0].indexOf("_")+1);
					var lng = tab_contenu[1].substr(tab_contenu[1].indexOf("_")+1);
					var content = tab_contenu[2].substr(tab_contenu[2].indexOf("_")+1);

					if(lat != "n" && lng != "n")
					{
						tab_markers[i] = {
							latitude : lat,
							longitude : lng,
							infoBoxContent : content,
						}				
						i++;
					}

				});
				
				$("#googlemap").createMap(
				{
					multipleMarkers : true,
					infoBox : true,
					infoBoxOpen : false,
					markers : tab_markers,		
				});
			   
			});
			request.fail(function(jqXHR, textStatus) 
			{
				alert( "Erreur lors de init_google_map: " + textStatus );
			});
			
			
			
		}
		else
		{
			
			
		}
		
			
		
	}
}

function live_search()
{
	var value=$("#list_keyword").val();
	
	$(".mode").val('list');
	$("#edit_form_container").html('').addClass('hide');
	$("#mig_list_display").removeClass('hide');
    $(".search_panel").fadeIn("fast");
	$("#list_keyword").focus();
	$(".search_element").removeAttr('disabled');
	
	$("html, body").animate({ scrollTop: 0 }, 0);
	
	
	$("#page").val(1);
	$("#special_status").html('Recherche sur <b>'+value+'</b>').show();

	setTimeout(function()
	{
		  $("#migc4_main_table").attr('style','opacity:0.5!important');
		  if ($("#list_keyword").val() == value)
		  {
			get_list_body();
		  }
		  else
		  {
		  }
	},500);
}


function initialiser_champs_speciaux()
{
	$("#migc4_main_table").removeAttr('style');
	$('textarea').autosize();
	//$('.zoo-item').ZooMove();
		
    init_data_types();
    init_edit_tabs();
    init_shortcuts();
	init_listboxtable_treeview();
	
	//tooltip
	$('.label').tooltip({html:'true'});
	$('.badge').tooltip({html:'true'});
	$('i').tooltip({html:'true'});
	$('a').tooltip({html:'true'});
	$('.span_tooltip').tooltip({html:'true'});
	if(isTouchDevice()===false) 
	{
		$('.label').tooltip().tooltip('hide');
		$('.badge').tooltip().tooltip('hide');
		$('i').tooltip().tooltip('hide');
		$('a').tooltip().tooltip('hide');
		$('.span_tooltip').tooltip().tooltip('hide');
	} 
	
}


//INITIALISATIONS APRES RECHARGEMENT LISTING
function re_init()
{
	
	
	
	var custom_func_listing = jQuery('#javascript_custom_func_listing').val();
	
	if(custom_func_listing == '' || typeof custom_func_listing == 'undefined')
	{
		custom_func_listing = 'dum';
	}           
	window[custom_func_listing]();
}

function change_page()
{
    $("#page").val($(this).attr('id'));
	// console.log('change_page');
    get_list_body();
    return false
}

function admin_list_pagination_begin()
{
    // console.log('admin_list_pagination_begin');
	if($(this).hasClass('disabled'))
    {
    }
    else
    {
        $("#page").val(1);
        //console.log('alpb');
		get_list_body();
    }
    return false
}

function admin_list_pagination_previous()
{
    if($(this).hasClass('disabled'))
    {
    }
    else
    {
        $("#page").val(parseInt($("#page").val())-1);
        get_list_body();
    }
    return false
}

function admin_list_pagination_next()
{
    if($(this).hasClass('disabled'))
    {
    }
    else
    {
        $("#page").val(parseInt($("#page").val())+1);
        get_list_body();
    }
    
    return false
}

function admin_list_pagination_end()
{
    if($(this).hasClass('disabled'))
    {
    }
    else
    {
        $("#page").val($("#last_page").val());
		get_list_body();
    }
   
    return false
}

function list_launch_search()
{       
    $(".page").val(1);
	
	$(".mode").val('list');
	$("#edit_form_container").html('').addClass('hide');
	$("#mig_list_display").removeClass('hide');
    $(".search_panel").fadeIn("fast");
	$("#list_keyword").focus();
	$(".search_element").removeAttr('disabled');
	
	
    get_list_body();
    return false;
}

function list_refresh()
{
    $(".page").val(1);
	
	$(".mode").val('list');
	$("#edit_form_container").html('').addClass('hide');
	$("#mig_list_display").removeClass('hide');
    $(".search_panel").fadeIn("fast");
	$("#list_keyword").focus();
	$(".search_element").removeAttr('disabled');
	
    $("#nr").val(25);
    $("#list_keyword").val('');
    $("#list_specific_col").val('');
    $(".list_filter").val('');
    get_list_body();
}

function get_list_body(id,sens,render,restauration_active,callback)
{

	$(".se-pre-con").fadeIn("fast");
    $("#sorting_box").fadeOut("fast");
    
    var page = $("#page").val();
	var colg = $(".colg").val();
    var nr = $("#nr").val();
    var list_keyword = $("#list_keyword").val();
	var list_tags_vals = $("#list_tags_vals").val();
    var list_specific_col = $("#list_specific_col").val();
    var list_count_filters = parseInt($("#list_count_filters").val());
    var filters = '';
    var sort_field_name = $("#sort_field_name").val();
    var sort_field_sens = $("#sort_field_sens").val();
    var extra_filter_value = $("#extra_filter").val();
    var extra_filter_name = $("#extra_filter").attr('name');
    var extra_filter = '';
        
    for(var i = 1;i<list_count_filters;i++)
    {
        var name = $("#list_filter_"+i).attr('name');
        var value = $("#list_filter_"+i).val();
        filters += name+'---'+value+'___';    
    }
	if(extra_filter_value > 0)
	{
		extra_filter = extra_filter_name+'---'+extra_filter_value;    
	}
    
    var nb_col = $("#migc4_main_table thead tr th").length;
    
	var report_range_name = $('.report_range').attr('name');
	var report_range_value = $('.report_range').val();
	
    var list_func = $("#list_func").val();
	
	var data_object = 
   {
           sw : list_func,
           page : page,
           nr : nr,
           list_keyword : list_keyword,
		   list_tags_vals : list_tags_vals,
           list_specific_col : list_specific_col,
           filters : filters,
           extra_filter : extra_filter,
           id : id,
		   lg : colg,
           sens : sens,
           render : render,
		   report_range_name : report_range_name,
           report_range_value : report_range_value,
           sort_field_name : sort_field_name,
           sort_field_sens : sort_field_sens,
		   restauration_active: $("#restauration_active").val()
   };
	
	$(".parametre_url").each(function(i)
	{
		var me = $(this);
		var nom = me.attr('name');
		var valeur = me.val();
		
		if(nom != '' && valeur != '') 
		{
			if(nom == 'sw' && (valeur == 'add_form' || valeur == 'mod_form'))
			{
				valeur = 'list_body_ajax';
			}
			data_object[nom] = valeur;	
		}
	});

    var request = $.ajax(
    {
        url: self,
        type: "GET",
        data: data_object,
        dataType: "html"
    });
    
    request.done(function(msg) 
    {	
		if($("#page_func").length > 0 || $("#list_func").val() != 'list_body_ajax')
		{
			window.location.reload();
		}
		else
		{
			$(".se-pre-con").fadeOut("fast");
			if(render == 'txt')
			{
				downloadFile(msg);
			}
			else
			{
				if(render == 'excel')
				{
					  var filename = msg.replace("../usr/documents/", ""); 	
					  swal({
						  title: "Votre fichier a été créé",
						  text: "<a href='"+msg+"' target='_blank' class='btn btn-success'><i class='fa fa-eye'></i> Ouvrir le fichier</a> <a href='"+msg+"' download='"+filename+"' class='btn btn-success'><i class='fa fa-download'></i> Télécharger le fichier</a>",
						  html: true,
						  confirmButtonText: 'Fermer',
						  type: "success"
						});
					
					jQuery('.sa-confirm-button-container').show();
				}
				else
				{
					var result = msg.split('___');
					if(list_func == 'list_body_ajax')
					{
						$("#migc4_main_table tbody").html(result[0]);
						$(".pagination_container").html(result[1]);
						$("#last_page").val(result[2]);
						$(".admin_list_pagenumber").html(result[3]);
						$(".admin_list_totalresults").html(result[4]);
						$("#custom_header").html(result[5]);
						$(".pagination").show();
						re_init();
						initialiser_champs_speciaux();
						$("#special_status").html('');
					}
					else
					{
						$("#mig_list_display").html(msg);
					}
					
					if(typeof callback != 'undefined')
					{
						callback();
					}
				}  
			}
		}		
		init_google_map();
		
  });      
        
  request.fail(function(jqXHR, textStatus) 
  {
  });
}



window.downloadFile = function (sUrl) 
{
	
    //iOS devices do not support downloading. We have to inform user about this.
    if (/(iP)/g.test(navigator.userAgent)) {
        alert('Your device do not support files downloading. Please try again in desktop browser.');
        return false;
    }

    //If in Chrome or Safari - download via virtual link click
    if (window.downloadFile.isChrome || window.downloadFile.isSafari) {
        //Creating new link node.
        var link = document.createElement('a');
        link.href = sUrl;

        if (link.download !== undefined) {
            //Set HTML5 download attribute. This will prevent file from opening if supported.
            var fileName = sUrl.substring(sUrl.lastIndexOf('/') + 1, sUrl.length);
            link.download = fileName;
        }

        //Dispatching click event.
        if (document.createEvent) {
            var e = document.createEvent('MouseEvents');
            e.initEvent('click', true, true);
            link.dispatchEvent(e);
            return true;
        }
    }

    // Force file download (whether supported by server).
    var query = '?download';

    window.open(sUrl + query, '_self');
}

window.downloadFile.isChrome = navigator.userAgent.toLowerCase().indexOf('chrome') > -1;
window.downloadFile.isSafari = navigator.userAgent.toLowerCase().indexOf('safari') > -1;

function cancel_edit()
{
    $(".mode").val('list');
    
	$("#edit_form_container").html('').addClass('hide');
	$("#mig_list_display").removeClass('hide');
	
	
    $(".search_panel").fadeIn("fast");
	$("#list_keyword").focus();
	$(".search_element").removeAttr('disabled');
	
	show_list();
	
	$("html, body").animate({ scrollTop: scrollbarposition }, 0);

    return false;
}


function migadd()
{
    $(".mode").val('add');
	var id = 0;
	history.pushState({state: 'ajout',id_record:0}, 'ajout',self);
	
	var autocreation = $("#autocreation").val();
	if(autocreation == 1)
	{
	   var request = $.ajax
	   (
	   {
			url: self+'&sw=edit_db_ajax',
			type: 'GET',     
			cache: false,
			async:true,
			contentType: false,
			processData: false
	   });
	   
	   request.done(function(new_id) 
	   {
			var id = new_id;
			var self = get_self('full');
			history.pushState({state: 'edit',id_record:id}, 'edit',self);
			edit_record(id);
	   });
	}
	else
	{
		edit_record(id,$(".colg").val());
	}
	
	return false;
}

function migedit()
{
    $(".mode").val('edit');
    var id = $(this).attr('id');
	var self = get_self('full');
	scrollbarposition = $(document).scrollTop();
	history.pushState({state: 'edit',id_record:id}, 'edit',self);
	edit_record(id,$(".colg").val());
    return false;
}

function dupliquer()
{  
    var id = $(this).attr('id');
	var self = get_self('full');
	
	var request = $.ajax(
    {
        url: self+'&sw=dupliquer&id='+id,
        type: "GET",
        dataType: "html"
    });
    
    request.done(function(content) 
    {	
		get_list_body();
	});
	
    return false;
}

function lock_on()
{  
    var id = $(this).attr('id');
	var self = get_self('full');
	
	
	
    swal({   
   title: "Verrouiller ? ",   
   text: "Une fois verrouillé, l'élément ne sera plus modifiable.",   
   type: "warning",   
   showCancelButton: true,   
   confirmButtonColor: "#DD6B55",   
   confirmButtonText: "Oui, verrouillez le !",   
   cancelButtonText: "Non, ne rien faire",   
   closeOnConfirm: false,   
   closeOnCancel: false }, 
   function(isConfirm)
   {   
		
		
		if (isConfirm)
		{     
			
			swal({title:"Verrouillé !", text:"L'enregistrement a été verrouillé. En cas d'erreur, contactez un administrateur pour le déverrouiller.", type:"success"});  
			
			var request = $.ajax(
			{
				url: self+'&sw=lock_on&id='+id,
				type: "GET",
				dataType: "html"
			});
			
			request.done(function(content) 
			{	
				get_list_body();
			});
			
		} 
		else 
		{     
			swal({title:"Annulé", text:"L'enregistrement n'a pas été verrouillé", type:"error", timer: 2000});   
		} 
	}
	);
    return false;
}

function lock_off()
{  
    var id = $(this).attr('id');
	var self = get_self('full');
	
	var request = $.ajax(
    {
        url: self+'&sw=lock_off&id='+id,
        type: "GET",
        dataType: "html"
    });
    
    request.done(function(content) 
    {	
		get_list_body();
	});
	
    return false;
}

function edit_record(id,force_colg,force_colg_compare)
{
   $(".se-pre-con").fadeIn("fast");
   $(".search_element").attr('disabled','disabled');
   $("#mig_list_display").addClass('hide');
   $(".edit_id").val(id);
   if(id > 0)
   {
	   $(".menu-trad").removeClass('hide');	   
   }
   else
   {
	   $(".menu-trad").addClass('hide');	   
   }
   var edit_func = $("#edit_func").val();
   $(".show_only_after_document_ready").attr('disabled','disabled');
   
   var data_object = 
   {
           sw : edit_func,
           id : id,
           force_colg: force_colg,
           force_colg_compare: force_colg_compare,
    };
	$(".parametre_url").each(function(i)
	{
		var me = $(this);
		var nom = me.attr('name');
		var valeur = me.val();
		
		if(nom != '' && valeur != '') 
		{
			data_object[nom] = valeur;	
		}
	});
	data_object['sw'] = edit_func;	
	data_object['id'] = id;	
	data_object['force_colg'] = force_colg;	
	data_object['force_colg_compare'] = force_colg_compare;	
   var request = $.ajax(
    {
        url: self,
        type: "GET",
        data: data_object,        
        dataType: "html"
    });
    
    request.done(function(content) 
    {
		$("#edit_form_container").html(content).removeClass("hide").hide().fadeIn("fast");
		initialiser_champs_speciaux();
		mig_post_edit_form();
		
    });
	
    request.fail(function(jqXHR, textStatus) 
    {
		$(".show_only_after_document_ready").removeAttr('disabled');
		//$(".se-pre-con").fadeOut("fast");
    });
    return false;
}

function mig_post_edit_form()
{
	$(".show_only_after_document_ready").removeAttr('disabled');
		
		init_valid_form('admin_edit_form');
		
		if(jQuery('.dropzone_container').length)
		{
			load_files_admin();
		}
		
		//init_data_types();
		// init_edit_tabs();
		// init_shortcuts();
		// init_listboxtable_treeview();
		
		tinymce.init({
			selector: ".wysiwyg",
			forced_root_block : false,
			language : 'fr_FR',
			inline: false,
			theme: "modern",
			entity_encoding : "raw",
			file_browser_callback: bugi_link_browser,
			plugins: 
			[
			  "advlist autolink lists link image charmap hr pagebreak",
			  "searchreplace wordcount visualblocks visualchars code fullscreen",
			  "insertdatetime nonbreaking table contextmenu directionality",
			  "emoticons paste textcolor autoresize"
			]
			,
			toolbar1: " undo redo | styleselect | bold italic  underline forecolor | link image | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent | template  ",
			image_advtab: true,
			save_enablewhendirty: true,
			save_onsavecallback: bugi_save_parag,
			convert_urls : false,
			 link_class_list: 
			 [
				{title: 'Aucun', value: ''},
				{title: 'Mise en forme du lien 1', value: 'custom-style-lien-1'},
				{title: 'Mise en forme du lien  2', value: 'custom-style-lien-2'},
				{title: 'Mise en forme du lien  3', value: 'custom-style-lien-3'},
				{title: 'Mise en forme du lien  4', value: 'custom-style-lien-4'},
				{title: 'Mise en forme du lien  5', value: 'custom-style-lien-5'}
			 ]
			});
		
		//POST-FONCTION SUR MESURE PR LE FORMULAIRE
		var custom_func = jQuery('#javascript_custom_func_form').val();
		if(custom_func == '')
		{
			custom_func = 'dum';
		}           
		if(typeof custom_func != 'undefined')
		{
			//alert('call '+custom_func);
			window[custom_func]();
		}
		$(".se-pre-con").fadeOut("fast");
		
		var breadcrumb_height = $(".breadcrumb").height();
		var search_panel_height = $(".search_panel").height();
		var mig_tabs_height = $(".mig-tabs").height();
		if(mig_tabs_height == null) { lgview_height = 0; }
		$("html, body").animate({ scrollTop: breadcrumb_height + search_panel_height + mig_tabs_height }, 0);
		savetop();	
}

function dum(txt)
{
}

function get_self(what)
{
   var self = $("#self").val();
   if(self != '' && typeof self != 'undefined')
   {
	   console.log('self1:'+self);
	   return self;	   
   }
   
   var self_obj = window.location;

   var self = self_obj.protocol+'//'+self_obj.host+'/'+self_obj.pathname;
   if(what == 'full')                                                      
   {
      console.log('self2:'+self_obj.href);
	  return  self_obj.href;
   }
   else
   {
      //console.log('self3:'+self);
	  return self;
   }
}

function init_nr()
{
      
	  $("#nr").change(function()
      {
         $("#page").val(1);
         var new_nr = parseInt($("#nr").val());
         if(isNaN(new_nr))
         {
            $("#nr").val(5);
         }
         if(new_nr > 10000)
         {
            $("#nr").val(10000);
         }
         else
         {
            if(new_nr < 5)
             {
                $("#nr").val(5);
             }
         }
		 get_list_body();
      });
}

function init_edit_tabs()
{
	  if($(".mig_onglet").length > 0)
      {
          jQuery('.edit_group').hide();
          $(".mig_onglet").click(function()
          {
              jQuery('.edit_group').hide();
              jQuery('.edit_group_'+$(this).attr('id')).show();
              $(".mail-navigation .active").removeClass('active');
              $(this).parent().addClass('active');
              return false;
          });
          $(".mig_onglet").first().click();
          jQuery('.edit_group').first().show();
		  
		  load_func_tabs();

      }
}

function init_shortcuts()
{
    /*
	$(document).unbind( "keyup" );
    
	$(document).keyup(function (e) 
    {
        // console.log(e.which);
        var me = $(".mail-navigation .active");
        if(e.which == 37)
        {
            var precedent = me.prev('li');
            precedent.children('a').click();
        }
        if(e.which == 39)
        {
            var suivant = me.next('li');
            suivant.children('a').click(); 
        }
    });
	*/
} 

function admin_save_form(no_redir,callback)
{
       var id = $(".edit_id").val();
       var colg = $(".colg").val();
	   
	   $(".show_only_after_document_ready").attr('disabled','disabled');
	   	var submit = true;
		
		var form = $('.admin_edit_form');
			
		if( !validator.checkAll( form ) )
		{
			submit = false;
		}

		if(!submit)
		{
			$(".show_only_after_document_ready").removeAttr('disabled');
			return false;			
		}
	 
	   
	   
	   var formData = new FormData();
	   
       $(".cbsaveme").each(function(i)
       {
		  if ($(this).is(':checked')) 
		  {
			  //donnees[$(this).attr('name')] = 'y';
			  formData.append($(this).attr('name'), "y");
		  }
		  else
		  {
			  //donnees[$(this).attr('name')] = 'n';
			  formData.append($(this).attr('name'), "n");
		  }
       });
       $("input.saveme").each(function(i)
       {
          //donnees[$(this).attr('name')] = $(this).val();
		  formData.append($(this).attr('name'), $(this).val());
       });
       $("select.saveme").each(function(i)
       {
          // donnees[$(this).attr('name')] = $(this).val();
		  formData.append($(this).attr('name'), $(this).val());
       });
	   $("textarea.saveme").each(function(i)
       {
            // donnees[$(this).attr('name')] = $(this).val();
			if($(this).hasClass('wysiwyg'))
			{
				//rien: on sauve le tinymce plus tard
			}
			else
			{
				formData.append($(this).attr('name'), $(this).val());
			}
       });
	   
       $("textarea.wysiwyg").each(function(i)
       {
            var this_name = $(this).attr('id');
            tinyMCE.get(this_name).save();
			formData.append($(this).attr('name'), $(this).val());
       });
       
	    $("input.saveme_tel").each(function(i)
       {
			formData.append($(this).attr('name'), $(this).intlTelInput("getNumber"));
       });
	   
	   formData.append('sel', jQuery('input[name="sel"]').val());
	   formData.append('sw', 'edit_db_ajax');
	   formData.append('id', id);
	   formData.append('colg', colg);
	   formData.append('textcontents', jQuery('#textcontents').val());
	   
	   
       var request = $.ajax(
       {
            url: self,
            type: 'POST',     
			xhr: function() 
			{  
				var myXhr = jQuery.ajaxSettings.xhr();
				if(myXhr.upload)
				{ 
					myXhr.upload.addEventListener('progress',progressHandlingFunction, false); // For handling the progress of the upload
				}
				return myXhr;
			}
			,			
            data: formData,
			cache: false,
			async:true,
			contentType: false,
			processData: false
       });
	   
	    function progressHandlingFunction(e)
		{
			if(e.lengthComputable)
			{
				var perc = e.loaded / e.total;
				perc *= 100;
				perc = parseInt(perc);
				
				jQuery('.migcms_file_perc_progress').show();
				
				jQuery('.migcms_file_perc').html(perc+' %');
				jQuery('.migcms_file_perc').show();
				
				$(".migcms_file_perc_progress_bar").css('width',perc+'%');
			}
		}
       
       request.done(function(msg) 
       {
            $(".show_only_after_document_ready").removeAttr('disabled');
			
			jQuery('.migcms_file_perc_progress').hide();
			
			
		   	jQuery('.migcms_file_perc').html('0 %');
			jQuery('.migcms_file_perc').hide();
			$(".migcms_file_perc_progress_bar").css('width','0%');
		   
		   $(".cbsaveme").attr('checked','');
		  

		  $("input.saveme").each(function(i)
		   {
				$(this).val($(this).attr('rel'));
		   });
		  $("textarea.saveme").each(function(i)
		   {
				$(this).val($(this).attr('rel'));
		   });
			
		   $(".wysiwyg").each(function(i)
		   {
				 var id = $(this).attr('id');
				 var ed = tinymce.get(id);
				 ed.setContent('');
		   });
		   

		   if(id > 0)
           { 
              $.bootstrapGrowl('<h4><i class="fa fa-check"></i> L\'enregistrement #'+id+' a été sauvegardé.</h4>', { type: 'success',align: 'center',
                        width: 'auto',offset: {from: 'top', amount: 20}, delay: 5000});
           }
		   
		   $("html, body").animate({ scrollTop: 0 }, 0);
           if(no_redir != 'no_redir')
		   {
			   //console.log('admin_save_form');
			   get_list_body();
			   cancel_edit();
		   }
		   
		    if(typeof callback != 'undefined')
			{
				callback(msg);
			}
		   
           return msg;
       });
       
       request.fail(function(jqXHR, textStatus) 
       {
            $(".show_only_after_document_ready").removeAttr('disabled');
			return 0;
       });
}     
  


function edit_switch_language1()
{
   var me = $(this);
   $(".edit_switch_language1").removeClass('btn-info');
   $(".edit_switch_language1").removeClass('btn-default');
   $(".edit_switch_language1").addClass('btn-default');
   
   me.removeClass('btn-default');
   me.addClass('btn-info');
   
   var mode = $(".mode").val();
   
   if(mode == 'list')
   {
		var id_language = me.attr('id');
		var colg_compare = $('.colg_compare').val();
		$(".colg").val(id_language);
		get_list_body();	
		return false;
   }
   else
   {   
	   var id_language = me.attr('id');
	   
	   $(".edit_switch_language2").removeAttr('disabled');
	   $(".edit_switch_language2_"+id_language).attr('disabled','disabled');
	   
	   var colg_compare = $('.colg_compare').val();
	   $(".colg").val(id_language);
	   var id_record = $('.edit_id').val();
	   edit_record(id_record,id_language,colg_compare);
	   return false;
   }
   
}

function edit_switch_language2()
{
	
   var me = $(this);
   var id_language = me.attr('id');
   var colg = $('.colg').val();
   $(".colg_compare").val(id_language);
   var id_record = $('.edit_id').val();
    edit_record(id_record,colg,id_language);
   return false;
}

function search_toggle()
{
    $("#search_caret").toggleClass('fa-caret-right').toggleClass('fa-caret-down');
}

function noResultser(term) 
{
  return $('<span>').addClass('no-results').text("Aucun resultat pour "+term);
} 

function init_data_types()
{
	jQuery('.migselect').each(function(i)
	{
		var nb_options = jQuery(this).children('option').length;
		if(nb_options >= 10)
		{
			jQuery(this).selectpicker(
			{
				liveSearch:true,
				noneSelectedText:''
			});
		}
	});
	
	jQuery('.migcms_file_perc_progress').hide();
	jQuery('.migcms_file_perc').hide();
	 
	 $(".telinput").intlTelInput({
		 defaultCountry: "",
		 autoPlaceholder:false,
		 autoFormat:true,
		 allowExtensions:false,
		 preferredCountries : ["be","fr","lu","nl"],
		 utilsScript: "../mig_skin/js/libphonenumber.js"
      });
	  
$(".telinput").blur(function() 
{
  var telInput = $(this);
  if ($.trim(telInput.val())) {
    if(!(telInput.intlTelInput("isValidNumber")))
	{
		//alert("Le téléphone n'est pas valide");
		//telInput.select();
		telInput.addClass("error");
	}
	/*
	if (telInput.intlTelInput("isValidNumber")) 
	{
      validMsg.removeClass("hide");
    } else {
      telInput.addClass("error");
      errorMsg.removeClass("hide");
      validMsg.addClass("hide");
    }*/
  }
});

// on keydown: reset
$(".telinput").keydown(function() 
{
  var telInput = $(this);
  telInput.removeClass("error");
  //errorMsg.addClass("hide");
  //validMsg.addClass("hide");
});
	  
	
	
	$('textarea:not(.wysiwyg)').autosize();
	
	$('.edit_timepicker').timepicker({
        minuteStep: 15,
        showInputs: false,
        showSeconds: false,
        showMeridian: false,
        defaultTime:false
    }); 
    
    $('.edit_timepicker').mask("99:99");

   	 
	 $('.add_datepicker,.edit_datepicker').datepicker({
		format: "dd/mm/yyyy",
		weekStart: 1,
		todayBtn: "linked",
		language: "fr",
		keyboardNavigation: false,
		todayHighlight: true,
		autoclose:true
    });
	
	
 var today = new Date();
    var dd = today.getDate();
    var mm = today.getMonth()+1; //January is 0!

    var yyyy = today.getFullYear();
    if(dd<10){
        dd='0'+dd
    } 
    if(mm<10){
        mm='0'+mm
    } 
    var today = dd+'/'+mm+'/'+yyyy+' 15:36';
	
	
	
	jQuery('.datetimepicker').datetimepicker({
                locale: 'fr',
                format: 'D/M/YYYY HH:mm',
				showTodayButton:true,
				icons: {
                    time: "fa fa-clock-o",
                    date: "fa fa-calendar",
                    up: "fa fa-arrow-up",
                    down: "fa fa-arrow-down",
					previous: 'fa fa-arrow-left',
					next: 'fa fa-arrow-right',
					today: 'fa fa-arrow-down',
					clear: 'fa fa-times-circle',
					close: 'fa fa-times'
                }
	});
	
	$('.add_datepicker,.edit_datepicker').keypress(function()
	{
		$('.add_datepicker,.edit_datepicker').datepicker('hide');	
	});
	
	 
	 //bouton parcourir sur mesure
	 $(".click_next").unbind();
     $(".click_next").click(function()
	 {
		 var me = $(this);
		 me.next().click();
		 return false;
	 });
	 
     $(".mig_btn_cb_toggle").click(function()
     {
          var me = $(this);
          var voisin = me.next('.mig_btn_cb_container');
          voisin.children('input').click();
          
          var spec_class = 'cb_valide_'+voisin.children('input').attr('name');
          
          if(me.hasClass('btn-info'))
          {
            me.removeClass('btn-info').removeClass(spec_class).addClass('btn-default');  
          }
          else
          {
            me.addClass('btn-info').addClass(spec_class).removeClass('btn-default');
          }
     });
     
      $(".multiple_ .btn_change_listbox,.multiple_0 .btn_change_listbox").click(function()
      {
            var me = $(this);
            var parent = me.parent();
            parent.children('a').removeClass('btn-info').addClass('btn-default');
            me.removeClass('btn-default').addClass('btn-info');
            
            var listbox_id = me.attr('rel');
            var listbox_value = me.attr('id');
            $('.'+listbox_id).val(listbox_value).change();
            return false;
      });
      
      $(".multiple_1 .btn_change_listbox").click(function()
      {
            var me = $(this);
            var parent = me.parent();
            var field_id = me.attr('rel');
			
            
            me.toggleClass('btn-info');
            me.toggleClass('btn-default');
            
            var values = ',';
            parent.children('.btn-info').each(function(i)
            {
                var enfant = $(this);
                values += enfant.attr('id') + ',';
            });
            $('.'+field_id).val(values).change();
            return false;
      });
/*
	var request = $.ajax(
    {
        url: get_self(),
        type: "GET",
        data: 
        {
           sw : 'migcms_ajax_get_tinymce_data'
        },
        dataType: "html"
    });
    
    request.done(function(msg) 
    {
		var result = msg.split('___');
		
		var style_formats = result[0];
		var templates = result[1];
		
		tinymce.init({
		selector: ".wysiwyg",
		language : 'fr_FR',
		inline: false,
		theme: "modern",

		file_browser_callback: bugi_link_browser,
		plugins: 
		[
		  "advlist autolink lists link image charmap hr pagebreak",
		  "searchreplace wordcount visualblocks visualchars code fullscreen",
		  "insertdatetime nonbreaking table contextmenu directionality",
		  "emoticons paste textcolor template "
		]
		,
		toolbar1: " undo redo | styleselect | bold italic forecolor | link image | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent | template  ",
		image_advtab: true,
		save_enablewhendirty: true,
		save_onsavecallback: bugi_save_parag,
		style_formats: eval(style_formats),
		templates: eval(templates)
		});
       
    });
    request.fail(function(jqXHR, textStatus) 
    {
       
    });
*/
     
      $(".show_only_after_document_ready").removeAttr('disabled');

	  // $(".saveme_txt").focus(function() { $(this).select(); } );
	  
	  //apply masks on fields
	  $(".saveme_txt").each(function(i)
	  {
		var new_mask = $(this).attr('data-domask');
		
		if(new_mask != '' && typeof new_mask != 'undefined')
		{
			$(this).mask(new_mask);
		}
	  });
	  
	  //init valid form
	 $('.admin_edit_form').validatr(); 
	 
	 securepwd();
	  
	$(".update_autocomplete_txt").each(function(i)
	  {
		
			var url_autocomplete = $(this).attr('data-doautocomplete');
			var valeurs = new Bloodhound(
			{
				datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
				queryTokenizer: Bloodhound.tokenizers.whitespace,
				limit: 25,
				remote: url_autocomplete+'&query=%QUERY'
			});
			valeurs.initialize();
			
		
			
			$(this).typeahead(null, {
				name: 'desktopsearch',
				autoselect: false,
				displayKey: 'affichage',
				highlight :true,
				hint:false,
				source: valeurs.ttAdapter()
			});
			$(this).bind('typeahead:selected', function(obj, datum, name) 
			{   
				jQuery(this).val(datum.name);
			});
			$(this).bind('typeahead:opened', function(obj, datum, name) 
			{   
			});
			$(this).bind('typeahead:closed', function(obj, datum, name) 
			{   
			
			});
			$(this).bind('typeahead:autocompleted', function(obj, datum, name) 
			{   
				jQuery(this).val(datum.name);
			});
	  }); 
	 

	  
}



function check_all_cb()
{
     //alert('cacb');
	 $(".cb").prop("checked",this.checked);
	 
}

function link_changevis()
{
        $(".se-pre-con").fadeIn("fast");
        var me = jQuery(this);
        var conteneur = me.parent();
        var url = self;
		var url_alt = me.attr('data-url');
		if(url_alt != '')
		{
			url = url_alt;
		}
        var id = me.attr('id');
        
        jQuery.ajax(
        {
           type: "POST",
           url: url,
           data: "sw=list_changevis_ajax&id="+id,
           success: function(msg)
           {
               $(".se-pre-con").fadeOut("fast");
               if(me.hasClass('btn-warning'))
               {
                  me.removeClass('btn-warning').addClass('btn-success').html('<span class="fa fa-check  fa-fw"></span> ');
               }
               else
               {
                  me.addClass('btn-warning').removeClass('btn-success').html('<span class="fa fa-ban  fa-fw"></span> ');
               }
           }
        });
       
        return false;    
}

$(document).on("click", ".sorting", function()
{
	var col = jQuery(this).attr('id');
	jQuery('#sort_field_name').val(col);                                                
	jQuery('#sort_field_sens').val('ASC');
	$("#page").val(1);
	
	//console.log('sorting');
	get_list_body();
	jQuery('.sorting_asc').removeClass('sorting_asc').addClass('sorting');
	jQuery('.sorting_desc').removeClass('sorting_desc').addClass('sorting');
	jQuery(this).removeClass('sorting').addClass('sorting_asc');
	
	jQuery(this).removeClass('sorting').addClass('sorting_asc');
	jQuery('.sorting_icon').html('<i class="fa fa-sort"></i>');
	jQuery(this).children('.sorting_icon').html('<i class="fa fa-sort-asc"></i>');
	return false
});

$(document).on("click", ".sorting_asc", function()
{
	var col = jQuery(this).attr('id');
	jQuery('#sort_field_name').val(col);
	jQuery('#sort_field_sens').val('DESC');
	$("#page").val(1);
	
	//console.log('sorting_asc');
	get_list_body();
	jQuery('.sorting_asc').removeClass('sorting_asc').addClass('sorting');
	jQuery('.sorting_desc').removeClass('sorting_desc').addClass('sorting');   
	jQuery(this).removeClass('sorting_asc').addClass('sorting_desc');
	jQuery('.sorting_icon').html('<i class="fa fa-sort"></i>');
	jQuery(this).children('.sorting_icon').html('<i class="fa fa-sort-desc"></i>');
	return false
});    
    
function line_highlight(id_rec,type)
{
   if(id_rec > 0)
   {
       if(type != 'remove')
       {
           switch(type)
           {
              case 'danger':

                                break;
             case 'sel':
                                $(".line_highlight").removeClass('line_highlight'); 
                                $(".line_highlight_sel").removeClass('line_highlight_sel'); 
                                $(".rec_"+id_rec).addClass('line_highlight_sel');
                                break;                   
             default:                                                                           
                                break                            
           }
       }
       else
       {
          $(".rec_"+id_rec).removeClass('line_highlight').removeClass('line_highlight_danger');
       }
    }
}  


 
function clic_close_sorting_box()
{
	 $("#sorting_box").fadeOut("fast");
}
function clic_save_sorting_box()
{
	 save_sorting_box();
     $("#sorting_box").fadeOut("fast");
}    

function save_sorting_box(id_rec_alt)
{
    var id_rec = parseInt($("#new_ordby_id").val());
    if(!(id_rec>0))
    {
       id_rec = id_rec_alt;
    }
    var current_ordby = parseInt($("#new_ordby").val());
    if(current_ordby > 0)
    {
        change_ordby_db(current_ordby,id_rec);
    }
    return false;
}

function sorting_box_next()
{
    
	var id_rec = $("#new_ordby_id").val();
    var current_ordby = parseInt($("#new_ordby").val());
    if(current_ordby > 0)
    {
        current_ordby++;
        $("#new_ordby").val(current_ordby);
        change_ordby_db(current_ordby,id_rec);
    }
    return false;
}
function sorting_box_previous()
{
    var id_rec = $("#new_ordby_id").val();
    var current_ordby = parseInt($("#new_ordby").val());
    if(current_ordby > 1)
    {
        current_ordby--;
        $("#new_ordby").val(current_ordby);
        change_ordby_db(current_ordby,id_rec);
    }
    return false;
}
function sorting_box_first()
{
    var id_rec = $("#new_ordby_id").val();
    var current_ordby = parseInt($("#new_ordby").val());
    if(current_ordby > 0)
    {
        current_ordby = 1;
        $("#new_ordby").val(current_ordby);
        change_ordby_db(current_ordby,id_rec);
    }
    return false;
}

function sorting_box_last()
{
    var id_rec = $("#new_ordby_id").val();
    var current_ordby = parseInt($("#new_ordby").val());
    if(current_ordby > 0)
    {
        current_ordby = 'last';
        change_ordby_db(current_ordby,id_rec);
    }
    return false;
}

function bugi_link_browser(field_name, url, type, win)
{
      $(".mce-window,#mce-modal-block").hide();
	  
	  $(".modal-title").html('Chargement...');
	  $(".modal-body").html('Chargement...');
	  $('#myModal').modal('toggle');
		  
      var link_value = '';

      var request = jQuery.ajax(
      {
          url: 'adm_migcms_link_pages.pl?',
          type: "GET",
          data: 
          {
             sw : 'list_body_ajax',
             nr : 25,
             page : 1
          },
          dataType: "html"
      });
      
      request.done(function(msg) 
      {
          msg = msg.replace('______1____________','');
		  msg = msg.replace('___','');
		  
          
          var table  = '';
          
          table     += '<input type="hidden" name="mig_tab_selected" id="mig_tab_selected" value="mig_tab_pages" />';
          
          
           table     += '<ul class="nav nav-tabs" id="myTab">';
          table     += '<li class="active"><a href="#pages" id="mig_tab_pages">Lien vers une page</a></li>';
          table     += '<li><a href="#files" id="mig_tab_files">Lien vers un fichier</a></li>';
          table     += '</ul>';
          
          table     += '<div class="pull-right">';

           
         
          
          table     += '<div class="btn-group">';       
          table     += '<a   class="btn btn-warning2" data-dismiss="modal" aria-hidden="true"> Annuler </a>';
          table     += '<a   class="btn btn-success migcms_create_parag_link" data-dismiss="modal" aria-hidden="true"> Créer le lien </a>';
          table     += '</div>';
          

          table     += '</div>';
          table     += '<div style="clear:both;"></div>';
          
          
 
            table     += '<div class="tab-content">';
              table     += '<div class="tab-pane active" id="pages">';
                table     += '<table id="migc4_main_table" class="migcms_parag_links table table-condensed table-striped table-bordered table-hover no-margin migc4_main_table_1">';
                table     += '<tbody>';
                  table     += msg;
                table     += '</tbody>';
                table     += '</table>';
              table     += '</div>';
              table     += '<div class="tab-pane" id="files">';
                table     += '<div id="mig_files_manger_container"></div>';
              table     += '</div>';
            table     += '</div>';
          
          $(".modal-title").html('Créer un lien');
		  $(".modal-body").html(table);
		  
          jQuery("#custom_modal").html(table);
          
		  $('#mig_files_manger_container').load('adm_migcms_file_manager.pl?sw=list_files&pick_link=y');
		  
		  

          jQuery('#myTab a').click(function (e) 
          {
              e.preventDefault();
              jQuery(this).tab('show');
          })
          
          jQuery('#myTab a').click(function (e) 
          {
              jQuery('#mig_tab_selected').val(jQuery(this).attr('id'));
          })
          
          jQuery('.migcms_parag_links tbody tr td input').attr('type','radio').attr('name','bugi_link');
          
          jQuery('.migcms_create_parag_link').click(function (e) 
          {
              var type = $("#mig_tab_selected").val();
              if(type == 'mig_tab_files')
              {
				  var file_link = jQuery('.pick_link:checked').attr('rel');
                  if(file_link != '')
                  {
                      win.document.getElementById(field_name).value = file_link;
                      $(".mce-window,#mce-modal-block").show();
                  }
              }
              else
              {
                  var id_page = jQuery('.migcms_parag_links_page:checked').attr('id');
                  if(id_page > 0)
                  {
                      var balise = '<MIGC_PAGE_['+id_page+']_HERE>';
                      win.document.getElementById(field_name).value = balise;
                      $(".mce-window,#mce-modal-block").show();
                  }
              }
          })
          
      });
      request.fail(function(jqXHR, textStatus) 
      {
          alert( "Erreur du chargement:" + textStatus );
      }); 
}

function bugi_save_line() 
{
      var id_editor = jQuery(this).attr('id');
      var editor = jQuery("#"+id_editor);
      var content = editor.html();
      var id_elt = editor.parent().attr('id');
      var table_name = jQuery('#table_name').val();
      var col = editor.attr('rel');
      var url = $("#myself").val();
            
      jQuery.ajax(
      {
         type: "POST",
         url: url,
         data: "&sw=ajax_save_elt&id_elt="+id_elt+'&col='+col+'&table_name='+table_name+'&content='+encodeURIComponent(content),
         success: function(msg)
         {
            $('.bottom-right').notify({ message: { text: 'La valeur de l\'élément #'+id_elt+' a été sauvegardé avec succès.' }, type: "success" }).show();
         }
      });
}

function bugi_save_parag() 
{
      var type='';
      var id_editor = jQuery(this).attr('id');
      var editor = jQuery("#"+id_editor);
      var content = editor.html();
      var id_parag = editor.parents(".mig_parag_container").attr('id');
      if(editor.hasClass('parag_text_content'))
      {
          type = 'content';
      }
      else
      {
          type = 'title';
      }
      // console.log(type);
      // console.log(id_parag);
      // console.log(content);
      
      jQuery.ajax(
      {
         type: "POST",
         url: 'adm_migcms_parag.pl?',
         data: "&sw=ajax_save_parag&id="+id_parag+'&type='+type+'&content='+encodeURIComponent(content)+"&colg="+$(".colg").val(),
         success: function(msg)
         {
             $('.bottom-right').notify({ message: { text: 'Le paragraphe numéro #'+id_parag+' a été sauvegardé avec succès.' }, type: "success" }).show();
         }
      });
}

function migc_linker (field_name, url, type, win) 
{
	//alert("Field_Name: " + field_name + "\\nURL: " + url + "\\nType: " + type + "\\nWin: " + win); // debug/testing

//     var cmsURL = window.location.toString();    // script URL - use an absolute path!
//     if (cmsURL.indexOf("?") < 0) {
//         //add the type as the only query parameter
//         cmsURL = cmsURL + "?type=" + type;
//     }
//     else {
//         //add the type as an additional query parameter
//         // (PHP session ID is now included if there is one at all)
//         cmsURL = cmsURL + "&type=" + type;
//     }
// 
//     tinyMCE.activeEditor.windowManager.open({
//         file : '../cgi-bin/adm_cmstree.pl?lg=$config{current_language}&colg=$colg&sw=split_links',
//         title : '',
//         width : 800,  // Your dimensions may differ - toy around with them!
//         height : 500,
//         resizable : "yes",
//         inline : "yes",  // This parameter only has an effect if you use the inlinepopups plugin!
//         close_previous : "no"
//     }, {
//         window : win,
//         input : field_name
//     });
    return false;

  }
  
function list_delete(force_id)
{
   var id = 0;
   if(force_id > 0)
   {
      id = force_id;
   }
   else
   {
      id = parseInt($(this).attr('id'));
   }
   
   swal({   
   title: "Supprimer ?",   
   text: 'Tapez "del" ou "DEL" pour confirmer la suppression définitive.',   
   type: "input",   
   showCancelButton: true,   
   closeOnConfirm: false,   
   closeOnCancel: false,  
   animation: "slide-from-top",   
   confirmButtonColor: "#DD6B55",   
   confirmButtonText: "Oui, supprimez le !",   
   cancelButtonText: "Non, ne rien faire",   

   inputPlaceholder: "" }, 
   function(inputValue)
   {   
    
		   if (inputValue == 'del' || inputValue == 'DEL')
			{     

				swal({title:"Supprimé", text:"L'enregistrement a été définitivement supprimé.", type:"success", timer: 2000});   
				
				var request = $.ajax(
				{
					url: self,
					type: "GET",
					data: 
					{
					   sw : 'list_delete_ajax',
					   id : id
					},
					dataType: "html"
				});
				
				request.done(function(msg) 
				{
				   get_list_body();
				});
				request.fail(function(jqXHR, textStatus) 
				{
					alert( "Request failed5: " + textStatus );
				});
				
			} 
			else 
			{     
				swal({title:"Annulé", text:"L'enregistrement n'a pas été supprimé", type:"error", timer: 2000});   
			} 
	   
   });
    return false;
}

function list_corbeille(force_id)
{
   var id = 0;
   if(force_id > 0)
   {
      id = force_id;
   }
   else
   {
      id = parseInt($(this).attr('id'));
   }
   
   swal({   
   title: "Archiver ? ",   
   text: "Voulez-vous réellement archiver et effacer cet élément ?",   
   type: "warning",   
   showCancelButton: true,   
   confirmButtonColor: "#DD6B55",   
   confirmButtonText: "Oui, archivez le !",   
   cancelButtonText: "Non, ne rien faire",   
   closeOnConfirm: false,   
   closeOnCancel: false }, 
   function(isConfirm)
   {   
		
		
		if (isConfirm)
		{     
			
			swal({title:"Archivé !", text:"L'enregistrement a été archivé. En cas d'erreur, contactez un administrateur pour le restaurer.", type:"success"});  
			
			var request = $.ajax(
			{
				url: self,
				type: "GET",
				data: 
				{
				   sw : 'list_corbeille_ajax',
				   id : id
				},
				dataType: "html"
			});
			
			request.done(function(msg) 
			{
			   get_list_body();
			});
			request.fail(function(jqXHR, textStatus) 
			{
			});
			
		} 
		else 
		{     
			swal({title:"Annulé", text:"L'enregistrement n'a pas été archivé", type:"error", timer: 2000});   
		} 
	}
	);
    return false;
}

function list_restaurer(force_id)
{
   var id = 0;
   if(force_id > 0)
   {
      id = force_id;
   }
   else
   {
      id = parseInt($(this).attr('id'));
   }
   
   swal({   
   title: "Restaurer ? ",   
   text: "Voulez-vous réellement restaurer cet élément ?",   
   type: "warning",   
   showCancelButton: true,   
   confirmButtonColor: "#DD6B55",   
   confirmButtonText: "Oui, restaurez le !",   
   cancelButtonText: "Non, ne rien faire",   
   closeOnConfirm: false,   
   closeOnCancel: false }, 
   function(isConfirm)
   {   
		
		
		if (isConfirm)
		{     
			swal({title:"Restauré", text:"L'enregistrement a été restauré", type:"success", timer: 2000});   
			
			var request = $.ajax(
			{
				url: self,
				type: "GET",
				data: 
				{
				   sw : 'list_restaurer_ajax',
				   id : id
				},
				dataType: "html"
			});
			
			request.done(function(msg) 
			{
			   get_list_body();
			});
			request.fail(function(jqXHR, textStatus) 
			{
			});
			
		} 
		else 
		{     

								swal({title:"Annulé", text:"L'enregistrement n'a pas été restauré", type:"error", timer: 2000});   
			
		} 
	}
	);
    return false;
}


function action_globale_pdfzip()
{
  
   var url_alt = $(this).attr('data-url');
   
   var ids = '';
   $(".cb").each(function(i)
   {
        var me = $(".cb").eq(i);
        var id = me.prop('id');
		
		
        if(this.checked)
        {
            ids += id+',';
        } 
   });    

   
   if(url_alt != '')
	{
		self = url_alt;
	}
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
			swal({
			  title: "Compression des fichiers...",
			  text: "",
			  html: true,
			  confirmButtonText: 'Fermer',
			  imageUrl: '../mig_skin/img/loader-big-noanimation.svg'
			});
			jQuery('.sa-custom').css('background-image','url(../mig_skin/img/loader-big.svg)');
			
			 var request = $.ajax(
			{
				url: self,
				type: "GET",
				data: 
				{
				   sw : 'list_action_globale_pdfzip_ajax',
				   ids : ids
				},
				dataType: "html"
			}); 
			
			request.done(function(msg) 
			{
				$("#check_all_cb").attr('checked',false);
				//var filename = msg.replace("../usr/documents/", ""); 	
				jQuery(this).attr('href',msg);
				window.open(msg);		
				swal.close();
				get_list_body();
			});
			request.fail(function(jqXHR, textStatus) 
			{			
				swal.close();
			});
			return false;
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
   // var request = $.ajax(
    // {
        // url: self,
        // type: "GET",
        // data: 
        // {
           // sw : 'list_action_globale_pdfzip_ajax',
           // ids : ids
        // },
        // dataType: "html"
    // });   
     
    // request.done(function(msg) 
    // {
       // $("#check_all_cb").attr('checked',false);
       // if(1 || url_alt == '')
	   // {
			// alert("zip ...");
			// get_list_body();
			
	   // }
	   // else
	   // {
		  $(".active").click();
	   // }
    // });
    // request.fail(function(jqXHR, textStatus) 
    // {
        // alert( "Request failed2: " + textStatus );
    // });
    return false;
}

function action_globale_show()
{
  
   var url_alt = $(this).attr('data-url');
   
   var ids = '';
   $(".cb").each(function(i)
   {
        var me = $(".cb").eq(i);
        var id = me.prop('id');
		
		
        if(this.checked)
        {
            ids += id+',';
        } 
   });    

   
   if(url_alt != '')
	{
		self = url_alt;
	}
   var request = $.ajax(
    {
        url: self,
        type: "GET",
        data: 
        {
           sw : 'list_action_globale_show_ajax',
           ids : ids
        },
        dataType: "html"
    });   
     
    request.done(function(msg) 
    {
       $("#check_all_cb").attr('checked',false);
       if(1 || url_alt == '')
	   {
			get_list_body();
	   }
	   else
	   {
		  // $(".active").click();
	   }
    });
    request.fail(function(jqXHR, textStatus) 
    {
        alert( "Request failed2: " + textStatus );
    });
    return false;
}
 
function action_globale_hide()
{
    var url_alt = $(this).attr('data-url');
	
   var ids = '';
   $(".cb").each(function(i)
   {
        var me = $(".cb").eq(i);
        var id = me.prop('id');
        if(this.checked)
        {
            ids += id+',';
        }
   });
   if(url_alt != '')
	{
		self = url_alt;
	}
   var request = $.ajax(
    {
        url: self,
        type: "GET",
        data: 
        {
           sw : 'list_action_globale_hide_ajax',
           ids : ids
        },
        dataType: "html"
    });
    
    request.done(function(msg) 
    {
       $("#check_all_cb").attr('checked',false);
       if(1|| url_alt == '')
	   {
			get_list_body();
	   }
	   else
	   {
		   //$(".active").click();
	   };
       
    });
    request.fail(function(jqXHR, textStatus) 
    {
        alert( "Request failed3: " + textStatus );
    });
    return false;
}




function action_globale_corbeille()
{

	swal({   
  title: "Archiver les éléménts cochés ?",   
  text: "Voulez-vous réellement archiver et éffacer les éléments cochés ?",   
   type: "warning",   
   showCancelButton: true,   
   confirmButtonColor: "#DD6B55",   
   confirmButtonText: "Oui, archivez les !",   
   cancelButtonText: "Non, ne rien faire",   
   closeOnConfirm: false,   
   closeOnCancel: false }, 
   function(isConfirm)
   {   
		
		
		if (isConfirm)
		{     
							
			swal({title:"Archivés !", text:"Les enregistrements ont été archivés. Contactez un administrateur pour les récupérer.", type:"success", timer: 2000});   


			var ids = '';
				$(".cb").each(function(i)
				{
					var me = $(".cb").eq(i);
					var id = me.prop('id');
					if(this.checked)
					{
						ids += id+',';
					}
				});
				var request = $.ajax(
				{
					url: self,
					type: "GET",
					data: 
					{
					   sw : 'list_action_globale_corbeille_ajax',
					   ids : ids
					},
					dataType: "html"
				});

				request.done(function(msg) 
				{
				   $("#check_all_cb").attr('checked',false);
				   get_list_body();
				   
				});
				request.fail(function(jqXHR, textStatus) 
				{
					alert( "Request failed4: " + textStatus );
				});
			
		} 
		else 
		{     
								swal({title:"Annulé", text:"Les enregistrements n'ont pas été archivés", type:"error", timer: 2000});   

		} 
	}
	);
    return false;


	
}

function action_globale_restauration()
{

	swal({   
  title: "Restaurer tous éléménts cochés ?",   
  text: "Voulez-vous réellement restaurer ces éléments ?",   
   type: "warning",   
   showCancelButton: true,   
   confirmButtonColor: "#DD6B55",   
   confirmButtonText: "Oui, restaurez les !",   
   cancelButtonText: "Non, ne rien faire",   
   closeOnConfirm: false,   
   closeOnCancel: false }, 
   function(isConfirm)
   {   
		
		
		if (isConfirm)
		{     
							
							swal({title:"Restaurés!", text:"Les enregistrements ont été restaurés", type:"success", timer: 2000}); 

			var ids = '';
				$(".cb").each(function(i)
				{
					var me = $(".cb").eq(i);
					var id = me.prop('id');
					if(this.checked)
					{
						ids += id+',';
					}
				});
				var request = $.ajax(
				{
					url: self,
					type: "GET",
					data: 
					{
					   sw : 'list_action_globale_restauration_ajax',
					   ids : ids
					},
					dataType: "html"
				});

				request.done(function(msg) 
				{
				   $("#check_all_cb").attr('checked',false);
				   get_list_body();
				   
				});
				request.fail(function(jqXHR, textStatus) 
				{
					alert( "Request failed4: " + textStatus );
				});
			
		} 
		else 
		{     
				swal({title:"Annulé", text:"Les enregistrements n'ont pas été restaurés", type:"error", timer: 2000});   
		} 
	}
	);
    return false;


	
}
function action_globale_delete()
{
	swal({   
   title: "Supprimer définitivement tous éléménts cochés ?",   
   text: 'Tapez "del" ou "DEL" pour confirmer la suppression définitive des élements cochés',   
   type: "input",   
   showCancelButton: true,   
   closeOnConfirm: false,   
   confirmButtonColor: "#DD6B55",   
   
   closeOnCancel: false,  
   animation: "slide-from-top",   
   confirmButtonText: "Oui, supprimez les !",   
   cancelButtonText: "Non, ne rien faire",   

   inputPlaceholder: "" }, 
   function(inputValue)
   {   
    
		   if (inputValue == 'del' || inputValue == 'DEL')
			{     
				swal("Supprimés!", "Les enregistrements ont été définitivement supprimés.", "success");   
				
				
				var ids = '';
				$(".cb").each(function(i)
				{
					var me = $(".cb").eq(i);
					var id = me.prop('id');
					if(this.checked)
					{
						ids += id+',';
					}
				});
				var request = $.ajax(
				{
					url: self,
					type: "GET",
					data: 
					{
					   sw : 'list_action_globale_delete_ajax',
					   ids : ids
					},
					dataType: "html"
				});

				request.done(function(msg) 
				{
				   $("#check_all_cb").attr('checked',false);
				   get_list_body();
				   
				});
				request.fail(function(jqXHR, textStatus) 
				{
					alert( "Request failed4: " + textStatus );
				});
				
			} 
			else 
			{     
							swal("Annulé", "Les enregistrements n'ont pas été supprimés", "error");   

			} 
	   
   });
    return false;
	
	
}

function action_globale_custom()
{
   if(confirm("Confirmer l'action sur les éléments cochés ?"))
   {
	   var sw = $(this).attr('id');
	   var ids = '';
	   $(".cb").each(function(i)
	   {
			var me = $(".cb").eq(i);
			var id = me.prop('id');
			if(this.checked)
			{
				ids += id+',';
			}
	   });
	   var request = $.ajax(
		{
			url: self,
			type: "GET",
			data: 
			{
			   sw : sw,
			   ids : ids
			},
			dataType: "html"
		});
		
		request.done(function(msg) 
		{
		   $("#check_all_cb").attr('checked',false);
		  
		   console.log('glb');
		   get_list_body();
		   if(sw == 'action_globale_excel')
		   {
			  Download('../usr/export_excel.xls');
		   }
		   
		});
		request.fail(function(jqXHR, textStatus) 
		{
			alert( "Request failed4: " + textStatus );
		});
    }
    return false;
}

function tab_mig_list_add()
{
	  alert('tab_mig_list_add');
	  $(".edit_id").val('');
	  $(".search_panel").hide();
	  //$.History.go('/add');
	  //history.pushState({state: 'ajout'}, 'ajout','../ajout');
	  var self = get_self('full');
	  history.pushState({state: 'ajout'}, 'ajout',self);
	  // show_add();
	  
	  var autocreation = $("#autocreation").val();
	  if(autocreation == 1)
	  {
		   var request = $.ajax
		   (
		   {
				url: self+'&sw=edit_db_ajax',
				type: 'GET',     
				cache: false,
				async:true,
				contentType: false,
				processData: false
		   });
		   
		   request.done(function(new_id) 
		   {
			    var id = new_id;
				var self = get_self('full');
				history.pushState({state: 'edit',id_record:id}, 'edit',self);
				edit_record(id);
		   });
	  }
	  else
	  {
	    show_add(); 
	  }
	  return false;
}

function show_add()
{
	$("#mig_list_display").hide();
	$("#tab_mig_list_edit").hide();	
	$(".list_tab").removeClass('active');
}


function return_to_list()
{
	//history.pushState({state: 'list'}, 'list','../list');
	var self = get_self('full');
	history.pushState({state: 'list'}, 'list',self);
	show_list();
}

function show_list()
{
	$(".mode").val('list');
	$(".menu-trad").addClass('hide');
    $(".search_panel").fadeIn("fast");
    $("#edit_form_container").html('').addClass('hide');
	$(".search_element").removeAttr('disabled');
	$("#mig_list_display").removeClass('hide');
}

function parag_template()
{
	var id_parag = $(this).attr('id');
	var id_template = $(this).val();
	var request = $.ajax(
    {
        url: self,
        type: "GET",
        data: 
        {
           sw : 'parag_template',
           id_parag : id_parag,
		   id_template: id_template
        },
        dataType: "html"
    });
    
    request.done(function(msg) 
    {
       console.log('parag_template');
	   get_list_body();
       
    });
    request.fail(function(jqXHR, textStatus) 
    {
    });
}

function load_func_tabs()
{
     
	 jQuery('.edit_group_func').each(function(i)
     {
          var me = jQuery(this);
          var donnees = new Object(); 
          var func = me.attr('id');
          var edit_id = jQuery('.edit_id').val();
          if(edit_id > 0)
          {
          }
          else
          {
              edit_id = me.attr('rel');
          }
          jQuery.ajax(
          {
             type: "POST",
             url: self,
             data: "&sw="+func+"&edit_id="+edit_id,
             success: function(msg)
             {
                me.html(msg);
				
				var javascript_after_load_func = jQuery('#javascript_after_load_func_'+func).val();
				if(javascript_after_load_func == '' || typeof javascript_after_load_func == 'undefined')
				{
					javascript_after_load_func = 'dum';
				}   
				window[javascript_after_load_func]();				
             }
          });
     });
}

function list_autosavecb()
{
	var me = jQuery(this);
	var conteneur = me.parent();
	var id = me.val();
	var col = me.attr('name');
						 
	var self = get_self();
	conteneur.html('<img src="../mig_skin/img/ajax-loader.gif" />');
	jQuery.ajax(
	{
	   type: "POST",
	   url: self,
	   data: '&sw=list_changecb_ajax&id='+id+"&col="+col,
	   success: function(msg)
	   {
		   conteneur.html(msg);
		   $(".se-pre-con").fadeOut("fast");
	   }
	});
	return false;    
}
	
	
function export_excel()
{       
	var id = jQuery(this).attr('id');
	
	swal({   
	title: 'Publication du fichier Excel...',   
	showCancelButton: true,   
	confirmButtonText: 'Commencer',   
	cancelButtonText: 'Annuler',   
	imageUrl: '../mig_skin/img/loader-big-noanimation.svg',
	closeOnConfirm: false }, 
	function() 
	{   
		jQuery('.sa-custom').css('background-image','url(../mig_skin/img/loader-big.svg)');
		jQuery('.sa-confirm-button-container').hide();
		jQuery('button.cancel').hide();
		
		$(".page").val(1);
		get_list_body('','','excel');
		
	/*	
		var request = jQuery.ajax(
		{
			url: self,
			type: "GET",
			data: 
			{
			   sw : 'download_pdf',
			   id : id,
			   tdoc: jQuery('.prefixe').val()
			},
			dataType: "html"
		});
		
		request.done(function(msg) 
		{

			
			swal({
			  title: "Votre fichier a été créé",
			  text: "<a href='"+msg+"' target='_blank' class='btn btn-success'><i class='fa fa-eye'></i> Ouvrir le fichier PDF</a> <a href='"+msg+"' download='"+msg+"' class='btn btn-success'><i class='fa fa-download'></i> Télécharger le fichier PDF</a>",
			  html: true,
			  confirmButtonText: 'Fermer',
			  type: "success"
			});
			
			jQuery('.sa-confirm-button-container').show();
		});
		request.fail(function(jqXHR, textStatus) 
		{
			//alert( "Erreur de traitement: " + textStatus );
			jQuery('.sa-confirm-button-container').show();
			jQuery('button.cancel').show();
		});
		*/

	});
	
	
	
	
	return false;
}

function export_txt()
{       
	$(".page").val(1);
	get_list_body('','','txt');
	return false;
}

function restauration_switch()
{       
	if($("#restauration_active").val() == 'restauration_active')
	{
		$("#restauration_active").val('');
	}
	else
	{
		$("#restauration_active").val('restauration_active');
	}
	get_list_body('','','');
	
	$(this).toggleClass('btn-info').toggleClass('btn-default');
	return false;
}

function Download(url) {
    document.getElementById('my_iframe').src = url;
};

function before(evt)
{
  // return "Si vous rechargez la page, vous pourriez perdre des informations non sauvegardées ou votre position parmis les onglets de cette page. Confirmez ?";
   //If the return statement was not here, other code could be executed silently (with no pop-up)
}

function after(evt)
{
   //This event fires too fast for the application to execute before the browser unloads
}

function init_valid_form(form_name_class)
{
	validator.message['empty'] = 'Veuillez compléter ce champ';
	validator.message['min'] = 'La valeur de champs est trop courte';
	validator.message['max'] = 'La valeur de champs est trop longue';
	validator.message['number_min'] = 'La valeur de champs est trop basse';
	validator.message['number_max'] = 'La valeur de champs est trop élevée';
	validator.message['url'] = 'URL invalide';
	validator.message['number'] = 'Nombre invalide';
	validator.message['email'] = 'Email invalide';
	validator.message['email_repeat'] = 'Les emails ne correspondent pas';
	validator.message['password_repeat'] = 'Les mots de passe ne correspondent pas';
	validator.message['select'] = 'Veuillez sélectionner une valeur';	
	
	$('.'+form_name_class)
		.on('blur', 'input[required], input.optional, select.required', validator.checkField)
		.on('change', 'select.required', validator.checkField)
		.on('keypress', 'input[required][pattern]', validator.keypress);

	
}

function load_files_admin()
{
	
	
	var self_script = get_self();
	var upload_parametres = '';
	
	upload_parametres += jQuery('#file_prefixe').val();
	upload_parametres += '-';
	upload_parametres += jQuery('.edit_id').val();
	upload_parametres += '-';
	upload_parametres += jQuery('#table_name').val();
	
	var self = 'migcms_simple_upload_file.pl?';
	
	$(".dropzone_container").each(function(i)
	{
		var fieldname = jQuery(this).attr('id');
		var label = jQuery(this).attr('rel');
		var field_upload_parametres = upload_parametres;
		field_upload_parametres += '-';
		field_upload_parametres += fieldname;
		
		jQuery('.dropzone_container_'+fieldname).html('<div class="files_dropzone_'+fieldname+' dropzone "></div><div id="'+fieldname+'" class="files_get_file_list files_get_file_list_'+fieldname+'"></div>');
		var myDropzone = new Dropzone(".files_dropzone_"+fieldname,
		{ 
			url: self+field_upload_parametres,
			methode : 'GET',
			parallelUploads: 1,
			dictDefaultMessage:label			
		});

		myDropzone.on("complete", function(file) 
		{
			refresh_files_admin();
			
			var request = jQuery.ajax(
			{
				url: self_script,
				type: "GET",
				data: 
				{
				   sw : 'dm_after_upload_file',
				   edit_id : $(".edit_id").val()
				},
				dataType: "html"
			});
			
			request.done(function(msg) 
			{			
				
			});
			
			
		});
		
	});
	
	refresh_files_admin();
}

function refresh_files_admin()
{
	var self = get_self('full');
	$(".files_get_file_list").each(function(i)
	{
		var filename = $(this).attr('id');
		
		var request = jQuery.ajax(
    {
        url: self,
        type: "GET",
        data: 
        {
           sw : 'refresh_files_admin',
           token : jQuery('.edit_id').val(),
		   filename : filename,
		   file_prefixe : jQuery('#file_prefixe').val()
        },
        dataType: "html"
    });
    
    request.done(function(msg) 
    {
	   jQuery('.files_get_file_list_'+filename).html(msg);
	   
	   //sort files
	  $(".sortable").sortable({stop: function( event, ui )
	  {
		  var new_position = ui.item.index();
		  var id_element = ui.item.attr('id');
		  var id_record = $(".table-sort").attr('id');
		  var table_name = $("#table_name").val();
		  
		  var request = jQuery.ajax(
			{
				url: self,
				type: "GET",
				data: 
				{
				   sw : 'set_new_ordby_linked_files',
				   new_position : new_position,
				   filename : filename,
				   id_element : id_element,
				   id_record : id_record,
				   table_name : table_name
				},
				dataType: "html"
			});
			
			request.done(function(msg) 
			{
			        $.bootstrapGrowl('<h4><i class="fa fa-check"></i> Position enregistrée</h4>', { type: 'success',align: 'center',
                     width: 'auto',offset: {from: 'top', amount: 20}, delay: 1000});
			});
			request.fail(function(jqXHR, textStatus) 
			{
			});
	  }});
	   
	   
	   //delete file
	   jQuery('.list_del_file').click(function()
		{
			var id_migcms_linked_file = jQuery(this).attr('rel');
			if(id_migcms_linked_file != '')
			{
				if(confirm("Voulez-vous supprimer le fichier "+jQuery(this).attr('title')+' ?'))
				{
					var request = jQuery.ajax(
					{
						url: self,
						type: "GET",
						data: 
						{
						   sw : 'list_del_file',
						   id_migcms_linked_file : id_migcms_linked_file
						},
						dataType: "html"
					});
					
					request.done(function(msg) 
					{
					   refresh_files_admin();
					});
					request.fail(function(jqXHR, textStatus) 
					{
					});
				
				}		
			}
			return false;
		});
       
    });
    request.fail(function(jqXHR, textStatus) 
    {
    });
		
		
	});
	
	
	
	
	
}

function operations_button()
{
	$(".search_element").attr('disabled','disabled');
   $("#mig_list_display").addClass('hide');
   $("#edit_form_container").html('<div class="text-right"><a class="btn btn-success btn-xs" disabled="disabled">Chargement...</a><a class="btn btn-link btn-xs" disabled="disabled">Chargement...</a></div><div class="widget-box"><div class="widget-title"><span class="icon"></span><h5 style="font-weight:normal"></h5></div><div class="widget-content-disabled"><p style="padding:15px;" class="bg-info">Chargement en cours...</p><div class="well" style="height:450px"></div></div></div>').removeClass('hide');
	
	var self = get_self('full');
	var request = jQuery.ajax(
	{
		url: self,
		type: "GET",
		data: 
		{
		   sw : 'get_operations_div'
		},
		dataType: "html"
	});
	
	request.done(function(msg) 
	{
	   $("#edit_form_container").html(msg);
	});
	request.fail(function(jqXHR, textStatus) 
	{
	});
	return false;
}

function isTouchDevice(){
    return true == ("ontouchstart" in window || window.DocumentTouch && document instanceof DocumentTouch);
}

function securepwd() {
	// Vérification mot de passe sécurisé
	"use strict";
	var options = {};
	options.ui = {
		container: ".securepwd",
		verdicts: [
			"<span class='fa fa-exclamation-triangle'></span> Très faible",
			"<span class='fa fa-exclamation-triangle'></span> Faible",
			"Moyen",
			"<span class='fa fa-thumbs-up'></span> Fort",
			"<span class='fa fa-thumbs-up'></span> Très fort"],
        showVerdictsInsideProgressBar: true,
		viewports: {
			progress: ".pwstrength_viewport_progress",
			verdict: ".pwstrength_viewport_verdict"
		}
	};
	options.common = {
		onLoad: function () {
			//$(".admin_edit_save").hide();
		},
		onKeyUp: function (evt, data) {
			if(data.score >= '25') {
				$(".btn-success").removeAttr("disabled");
			}
			else {
				$(".btn-success").attr("disabled","disabled");
			}
		},
		userInputs: ['#field_firstname', '#field_lastname'],
	};
	//$(':password').pwstrength(options);	
	$('.pwstrength_viewport_info i').tooltip({html:'true'});
	
	var nbr_progress = $('.pwstrength_viewport_progress > .progress').length;
	/*alert(nbr_progress);
	if(nbr_progress > 1) {
		$('.pwstrength_viewport_progress > .progress:last').remove();
	}*/
}

function makedotdotdot() {
	$(".mig-sitemap").find('.cell-value').dotdotdot({
		ellipsis	: '...',
		wrap		: 'letter'
	});
}

function seosimulatortitle() {
	var seotitle = $("#id_textid_meta_title_page").val();
	$('.seo-simulator h2').text(seotitle);
}

function seosimulatordescription() {
	var seodescr = $("#id_textid_meta_description_page").val();
	$('.seo-simulator-text').text(seodescr);
	$(".seo-simulator-text").dotdotdot({
		ellipsis	: '...',
		wrap		: 'letter'
	});
}

function headeractions() {
	// HEADER FIXED
	var headeractions_position = $(".header-actions").position();
	var headeractions_height = $(".header-actions").height();
	$(window).scroll(function () {
		if ($(this).scrollTop() > (headeractions_position.top + headeractions_height)) {
			$('.header-actions').addClass("fixed");
		}
		else {
			$('.header-actions').removeClass("fixed");
		}
	});
}

function savetop() {
	// SAVE TOP FIXED
	/*
	var savetop_position = $(".save-top").offset();
	var savetop_height = $(".save-top").height();
	var headersection_height = $(".header-section").height();
	var headeractions_height = $(".header-actions").height();
	$(window).scroll(function () {
		if ($(this).scrollTop() > (savetop_position.top - headersection_height - headeractions_height)) {
			$('.save-top').addClass("fixed");
		}
		else {
			$('.save-top').removeClass("fixed");
		}
	});
	*/
}



function init_listboxtable_treeview()
{
 var tree = $(".listboxtable_treeview"); 

	//TREE RADIO (un choix: multiple = 0)
	$(".listboxtable_treeview_0").jstree({
    "checkbox" : {
      "keep_selected_style" : false,
      "three_state" : false
    },
    "core": {
        "themes":{
            "icons":false
        },
	  "multiple" : false
    },
    "plugins" : [ "checkbox" ]
  });
  
  //TREE CHECKBOX (plusieurs choix)
  $(".listboxtable_treeview_").jstree({
    "checkbox" : {
      "keep_selected_style" : false,
      "three_state" : false
    },
    "core": {
        "themes":{
            "icons":false
        },
	  "multiple" : true
    },
    "plugins" : [ "checkbox" ]
  });
  
  
  $('.listboxtable_treeview').on("changed.jstree", function (e, data) {
		var field = $(this).attr("id");
		$(".field_"+field).val(data.selected);
	});


  $(".listboxtable_treeview").each(function(){
    $(this).jstree(true).open_all();
    init_treenode($(this));
    $(this).jstree(true).close_all();
     
  });
}


function init_treenode(tree){

$('li[data-checkstate="checked"]',tree).each(function() {
   tree.jstree('check_node', $(this));
});
}

function viewpdf()
{
	var id = jQuery(this).attr('id');
	var funcpublish = 'ajax_publish_pdf';
	if(jQuery(this).attr('data-funcpublish') != '')
	{
		funcpublish = jQuery(this).attr('data-funcpublish')
	}

	var href = jQuery(this).attr('href');
	if(href.length < 25)
	{
			swal({
			  title: "Génération en cours",
			  text: "",
			  html: true,
			  confirmButtonText: 'Fermer',
			  imageUrl: '../mig_skin/img/loader-big-noanimation.svg'
			});
			jQuery('.sa-custom').css('background-image','url(../mig_skin/img/loader-big.svg)');
			
			var request = jQuery.ajax(
			{
				url: self,
				type: "GET",
				data: 
				{
				   sw : funcpublish,
				   id : id,
				   tdoc: jQuery('.prefixe').val()
				},
				dataType: "html"
			});
			
			request.done(function(msg) 
			{
				//var filename = msg.replace("../usr/documents/", ""); 	
				jQuery(this).attr('href',msg);
				window.open(msg);		
				swal.close();
				get_list_body();
			});
			request.fail(function(jqXHR, textStatus) 
			{			
				swal.close();
			});
			return false;
			
	}
	else
	{
		window.open(href);
		return false;
	}
}

function check_session_validity()
{
	var self = get_self('full');
	//var self = $("#url_site").val()+'/cgi-bin/
	var request = jQuery.ajax(
	{
		url: self,
		type: "GET",
		data: 
		{
		   sw : 'check_session_validity',
		   sw_priority : 'check_session_validity'
		},
		dataType: "html"
	});
	
	request.done(function(msg) 
	{
		if(msg == '')
		{
			console.log(msg);
		}
		else
		{
			var logout_link = $("#logoutlink").attr('href');
			
			
			swal({   
		   title: "Vous avez été déconnecté. ",   
		   text: "Vous vous êtes connecté sur un autre ordinateur, navigateur, votre adresse IP a changé ou votre session a expiré.",   
		   type: "warning",   
		   showCancelButton: false,   
		   confirmButtonColor: "#DD6B55",   
		   confirmButtonText: "Connexion",   
		   cancelButtonText: "Fermer",   
		   closeOnConfirm: false,   
		   closeOnCancel: false }, 
		   function(isConfirm)
		   { 
				document.location.href=logout_link;
		   }
			);
		}
	});
	request.fail(function(jqXHR, textStatus) 
	{			
	});

}

function telecharger()
{
	var id = jQuery(this).attr('id');
	var me = jQuery(this);
	var funcpublish = 'ajax_publish_pdf';
	if(jQuery(this).attr('data-funcpublish') != '')
	{
		funcpublish = jQuery(this).attr('data-funcpublish')
	}

	var href = jQuery(this).attr('href');
	if(href.length < 25)
	{
			swal({
			  title: "Génération en cours",
			  text: "",
			  html: true,
			  confirmButtonText: 'Fermer',
			  imageUrl: '../mig_skin/img/loader-big-noanimation.svg'
			});
			jQuery('.sa-custom').css('background-image','url(../mig_skin/img/loader-big.svg)');
			
			var request = jQuery.ajax(
			{
				url: self,
				type: "GET",
				data: 
				{
				   sw : funcpublish,
				   id : id,
				   tdoc: jQuery('.prefixe').val()
				},
				dataType: "html"
			});
			
			request.done(function(msg) 
			{
				me.attr('href',msg);
				//setTimeout(function() {me.click(); }, 5000); 
				window.open(msg);		
				swal.close();
				get_list_body();
			});
			request.fail(function(jqXHR, textStatus) 
			{			
				swal.close();
			});
			return false;
	}
	else
	{
		return true;
	}
}

function send_by_email()
{
	var prefixe = $(".prefixe").val();
	scrollbarposition = $(document).scrollTop();	
	var id = $(this).attr('id');
	var self = get_self('full');
	$("#edit_form_container").html('Chargement...');
	
	swal({
	  title: "Préparation de l'email...",
	  text: "Préparation de l'email et génération des pièces jointes en cours...",
	  html: true,
	  confirmButtonText: 'Fermer',
	  imageUrl: '../mig_skin/img/loader-big-noanimation.svg'
	});
	
	var request = jQuery.ajax(
	{
		url: self,
		type: "GET",
		data: 
		{
			sw : 'send_by_email',
			id : id,
			prefixe: prefixe
		},
		dataType: "html"
	});

	request.done(function(msg) 
	{
		$("#edit_form_container").html(msg).toggleClass('hide');
		$("#mig_list_display").toggleClass('hide');
		swal.close();
		tinymce.remove();
		tinymce.init({
			selector: ".wysiwyg",
			forced_root_block : false,
			language : 'fr_FR',
			inline: false,
			  menubar: false,
			theme: "modern",
			plugins: 
			[
			  "advlist autolink lists link image charmap hr pagebreak",
			  "searchreplace wordcount visualblocks visualchars code fullscreen",
			  "insertdatetime nonbreaking table contextmenu directionality",
			  "emoticons paste textcolor  "
			]
			,
			toolbar1: " undo redo |  bold italic forecolor | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent   ",
			});
			
			
		
		$(".send_mail_screen_submit").click(function()
		{
			var to = $('.send_mail_screen_to').val();
			var send_mail_screen_object = $('.send_mail_screen_object').val();
			var send_mail_screen_cc = $('.send_mail_screen_cc').val();
			var send_mail_screen_cci = $('.send_mail_screen_cci').val();
			
			
			var send_mail_screen_message = '';//$('.send_mail_screen_message').html();
			
			var this_name = $('.mce-tinymce').attr('id');
            // console.log(this_name);
            //tinyMCE.get(this_name).save();
			//console.log($(this).val());
			//var content = tinymce.get(this_name).getContent({format: 'text'});
			var content = tinymce.activeEditor.getContent();
			//console.log('textarea wysiwyg: '+content);
            // donnees[$ (this).attr('name')] = $(this).val();
			
			send_mail_screen_message = content;
			var company = $(".company").val();
			var request2 = jQuery.ajax(
			{
				url: self,
				type: "POST",
				data: 
				{
					sw : 'send_by_email_db',
					company : company,
					to : to,
					cc : send_mail_screen_cc,
					cci : send_mail_screen_cci,
					object: send_mail_screen_object,
					id_doc : $(".id_doc").val(),
					prefixe_doc : $(".prefixe_doc").val(),
					send_mail_screen_message: send_mail_screen_message
				},
				dataType: "html"
			});

			request2.done(function(msg) 
			{
				swal({
				title: "Email envoyé",
				  text: "Votre document a bien été envoyé.",
				  html: true,
				  confirmButtonText: 'Fermer',
				  type: "success"
				});					
			
			});
			
			$("#edit_form_container").toggleClass('hide');
			$("#mig_list_display").toggleClass('hide');
			return false;
		});
		
		
	});
	return false;
	
	
	
	
}


/* ########### Googlemap contact ############ */
(function($) {

	$.fn.createMap = function (params) {

   		var params = $.extend({
   			// Default options
   			elementId : "googlemap",
   			address : "Rue d’Ans, 56 4000 Liège Belgique",
   			zoom : 15,
   			disableDefaultUI: true,
   			scrollwheel : false,
   			zoomControl : true,
   			simpleMarker : false, // Afficher un marker à l'adresse envoyée
   			multiMarkers : false, // Afficher plusieurs markers => Zoom et position de la carte automatique
   			icon : "../skin/img/googleMarker.png",
   			iconActive : "../skin/img/googleMarkerActive.png",
   			infoBox : false, // Afficher une infoBox pour chaque marker. Nécessite le plugin infobox
   			infoBoxOpen : false, // Ouvrir les infoBox au chargement
   			markers : {
   				0 : {
	   					"latitude" 				: "50.673789",
	   					"longitude"				: "5.544324", 
	   					"infoBoxContent"		: "<h1>Mon infoBox !</h1>",
   					},

				1 : {
					"latitude" 				: "50.783789",
					"longitude"				: "5.544324", 
					"infoBoxContent"		: "<h1>Mon infoBox !</h1>",
				},
   			}   			

   		}, params)

   		return this.each(function() {
   			// Create the map based on the adress
	   		var geocoder = new google.maps.Geocoder();
	   		geocoder.geocode( { 'address': params.address}, function(results, status) {
		      	if (status == google.maps.GeocoderStatus.OK) {

		      		// Get latitude and longitude
		        	var latitude = results[0].geometry.location.lat();
	      			var longitude = results[0].geometry.location.lng();

	      			var myMap = new google.maps.LatLng(latitude, longitude);
					var mapOptions = 
					{
						center: myMap,
				  		zoom: params.zoom,
				  		disableDefaultUI: params.disableDefaultUI,
				  		scrollwheel: params.scrollwheel,
				  		zoomControl: params.zoomControl,
				  		panControl: true,
						zoomControl: true,
						mapTypeControl: true,
						scaleControl: true,
						streetViewControl: true,
						overviewMapControl: true,

					};

					// Displaying de map							
					var map = new google.maps.Map(document.getElementById(params.elementId), mapOptions);


					/* Ajout d'un marker à l'adresse envoyée */
					if(params.simpleMarker)
					{
						var marker = new google.maps.Marker({
						 	map: map,
						 	draggable: false,
						 	position: new google.maps.LatLng(latitude, longitude),
						 	visible: true,
						 	icon: params.icon,
						});
					}

					/* Ajouts de plusieurs markers sur la carte */
					if(params.multipleMarkers)
					{
						// On parcourt les markers à ajouter
						var markers = params.markers;
						var markersOnMap = [];
						var infobox = [];
						var bounds = new google.maps.LatLngBounds();
						for(var key in params.markers)
						{

							// Ajouts de l'infoBox s'il faut
							if(params.infoBox) {

								infobox[key] = new InfoBox({
									    content: markers[key]["infoBoxContent"],
									    disableAutoPan: false,
									    maxWidth: 150,
									    pixelOffset: new google.maps.Size(-137, 0),
									    zIndex: null,
									    boxStyle: {
									                background: "url(../mig_skin/img/infobox-background.png)",
									                backgroundSize: "cover",
									                opacity: 1,
									                width: "270px",
									                maxWidth: "270px",
									                left:"494px",
									                height:"181px",
									        },
									    closeBoxMargin: "20px 10px 2px 2px",
									    closeBoxURL: "",
									    infoBoxClearance: new google.maps.Size(1, 1)
								});

							}

							// On place le marker
							markersOnMap[key] = new google.maps.Marker({
							    position: new google.maps.LatLng(markers[key]["latitude"], markers[key]["longitude"]),
							    map: map,
							    icon: params.icon,
							});

							//extend the bounds to include each marker's position
  							bounds.extend(markersOnMap[key].position);

							// Ouverture des infoBox
							if(params.infoBoxOpen)
							{
								markersOnMap[key].setIcon(params.iconActive); 
								infobox[key].open(map, markersOnMap[key])
							}
							else {
								// Ouverture / fermeture des infobox au click
								google.maps.event.addListener(markersOnMap[key], 'click', function(innerKey) {

										return function() {
										// On ferme toutes les infobox ouvertes et on remet les images d'origine
										for(var i=0 ; i<infobox.length ; i++){
											infobox[i].close();
											markersOnMap[i].setIcon(params.icon)
										}
										
										this.setIcon(params.iconActive);  
										infobox[innerKey].open(map, markersOnMap[innerKey])
										currentMark = this
									}


							  	}(key));

							  	// A la fermeture de l'infowindows on remet l'image du marker d'origine
							  	google.maps.event.addListener(infobox[key], 'closeclick', function(innerKey) {

									return function() {
										currentMark.setIcon(params.icon);  
										
									}

							  	}(key));


							}

							// On adapter l'affichage de la map aux markers
							//now fit the map to the newly inclusive bounds
							map.fitBounds(bounds);							
							
						}
					}
					

		      	} 
		      else {
		        console.log("Adresse inconnue");
		      }
		    });
		});
	}

})(jQuery);

//$('body').perfectScrollbar();
$('.left-side').perfectScrollbar();