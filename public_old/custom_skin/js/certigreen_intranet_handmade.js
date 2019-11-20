jQuery(document).ready(function() 
{
	jQuery(document).on("click", ".download_pdf_document", download_pdf_document);
	jQuery(document).on("click", ".confirm_invoicing", confirm_invoicing);
	jQuery(document).on("click", ".confirm_nc", confirm_nc);
});

function confirm_nc()
{
	var id = jQuery(this).attr('id');
	var numero = jQuery(this).attr('data-numerofac');
	swal({   
	title: 'Créditer la facture N° FA'+numero+'?',
	text:'<i class="fa fa-exclamation-triangle"></i> Vous devrez obligatoirement confirmer les montants de la NC pour que celle-ci soit créée. (Etape 2)',
	html:true,
	showCancelButton: true,   
	confirmButtonText: 'Créditer',   
	cancelButtonText: 'Annuler',   
	imageUrl: '../mig_skin/img/loader-big-noanimation.svg',
	closeOnConfirm: false }, 
	function() 
	{   
		jQuery('.sa-custom').css('background-image','url(../mig_skin/img/loader-big.svg)');
		jQuery('.sa-confirm-button-container').hide();
		jQuery('button.cancel').hide();
		var request = jQuery.ajax(
		{
			url: self,
			type: "GET",
			data: 
			{
			   sw : 'confirm_nc',
			   id : id,
			   tdoc: jQuery('.prefixe').val()
			},
			dataType: "html"
		});
		
		request.done(function(new_id_nc) 
		{
			window.location.href = '/cgi-bin/adm_handmade_certigreen_commandes.pl?&sel=1000273&sw=add_form&activ_nav=nc&id='+new_id_nc;
			
			/*var filename = msg.replace("../usr/documents/", ""); 	
			
			swal({
			  title: "Votre Note de Crédit a été créée",
			  text: "<a href='"+msg+"' target='_blank' class='btn btn-success'><i class='fa fa-eye'></i> Visualiser</a> <a href='"+msg+"' download='"+filename+"' class='btn btn-success'><i class='fa fa-download'></i>Télécharger/Imprimer</a>",
			  html: true,
			  confirmButtonText: 'Fermer',
			  type: "success"
			});
			get_list_body();
			jQuery('.sa-confirm-button-container').show();
			*/
		});
		request.fail(function(jqXHR, textStatus) 
		{
			
			jQuery('.sa-confirm-button-container').show();
			jQuery('button.cancel').show();
		});

	});
	return false;
}


function confirm_invoicing()
{
	var id = jQuery(this).attr('id');
	// var identifiant = jQuery('.rec_'+id).children('.col_identifiant').children('span').html();
	var identifiant = id;
	// var numero = jQuery('.rec_'+id).children('.cms_mig_cell_numero ').children('span').html();
	
	swal({   
	title: 'Facturer cette commande Ref #'+identifiant+'?',   
	text:'<i class="fa fa-exclamation-triangle"></i> Cette action est <b style="color:red">irréversible</b>, la facture du document <b>'+identifiant+'</b> sera générée et un numéro de facture lui sera associé.',
	html:true,
	showCancelButton: true,   
	confirmButtonText: 'Facturer',   
	cancelButtonText: 'Annuler',   
	imageUrl: '../mig_skin/img/loader-big-noanimation.svg',
	closeOnConfirm: false }, 
	function() 
	{   
		jQuery('.sa-custom').css('background-image','url(../mig_skin/img/loader-big.svg)');
		jQuery('.sa-confirm-button-container').hide();
		jQuery('button.cancel').hide();
		var request = jQuery.ajax(
		{
			url: self,
			type: "GET",
			data: 
			{
			   sw : 'confirm_invoicing',
			   id : id,
			   tdoc: jQuery('.prefixe').val()
			},
			dataType: "html"
		});
		
		request.done(function(msg) 
		{
			var filename = msg.replace("../usr/documents/", ""); 	
			
			swal({
			  title: "Votre facture est prête",
			  text: "<a href='"+msg+"' target='_blank' class='btn btn-success'><i class='fa fa-eye'></i> Visualiser</a> <a href='"+msg+"' download='"+filename+"' class='btn btn-success'><i class='fa fa-download'></i> Télécharger/Imprimer</a>",
			  html: true,
			  confirmButtonText: 'Fermer',
			  type: "success"
			});
			get_list_body();
			jQuery('.sa-confirm-button-container').show();
		});
		request.fail(function(jqXHR, textStatus) 
		{
			
			jQuery('.sa-confirm-button-container').show();
			jQuery('button.cancel').show();
		});

	});
	return false;
}

function download_pdf_document()
{
	var id = jQuery(this).attr('id');
	
	swal({   
	title: 'Préparation du document...',   
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
		var request = jQuery.ajax(
		{
			url: self,
			type: "GET",
			data: 
			{
			   sw : 'ajax_make_pdf_document',
			   id : id,
			   tdoc: jQuery('.prefixe').val()
			},
			dataType: "html"
		});
		
		request.done(function(msg) 
		{
			var filename = msg.replace("../usr/documents/", ""); 	
			
			swal({
			  title: "Votre fichier est prêt",
			  text: "<a href='"+msg+"' target='_blank' class='btn btn-success'><i class='fa fa-eye'></i> Visualiser</a> <a href='"+msg+"' download='"+filename+"' class='btn btn-success'><i class='fa fa-download'></i> Télécharger/Imprimer</a>",
			  html: true,
			  confirmButtonText: 'Fermer',
			  type: "success"
			});
			
			jQuery('.sa-confirm-button-container').show();
		});
		request.fail(function(jqXHR, textStatus) 
		{
			
			jQuery('.sa-confirm-button-container').show();
			jQuery('button.cancel').show();
		});

	});
	return false;
}


function send_mail_screen()
{
	var prefixe = $(".prefixe").val();
	
	var id = $(this).attr('id');
	var self = get_self('full');
	$("#edit_form_container").html('Chargement...');
	
	var request = jQuery.ajax(
	{
		url: self,
		type: "GET",
		data: 
		{
			sw : 'send_mail_screen',
			id : id,
			prefixe: prefixe
		},
		dataType: "html"
	});

	request.done(function(msg) 
	{
		$("#edit_form_container").html(msg).toggleClass('hide');
		$("#mig_list_display").toggleClass('hide');
		tinymce.remove();
		tinymce.init({
			selector: ".wysiwyg",
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
					sw : 'send_mail_screen_db',
					company : company,
					to : to,
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


function init_button_document(type_document)
{

	jQuery(document).on('click', '.details_doc', function(e)
    {
        admin_save_form('no_redir',function(id_document)
		{
			$("#edit_form_container").html("Chargement de l'étape 2");
			
			var type = jQuery('.type_document').val();
			var prefixe = jQuery('.prefixe').val();
			
			var self = get_self('full');
			history.pushState({state: 'edit'}, 'edit',self);
			
			var donnees = new Object();
			donnees['sw'] = 'certigreen_edit_document_lines';
			donnees['id'] = id_document;
			donnees['type'] = type;
			donnees['prefixe'] = prefixe;
			
		   var request = jQuery.ajax(
		   {
				url: self,
				type: 'POST',         
				data: donnees,
				dataType: "html"
		   });
			
		   request.done(function(msg) 
		   {
				$("#edit_form_container").html(msg);
               recalcul_totaux();


               $(".clear_line").click(function()
				{
					var me = $(this);
					var line = me.parent().parent().parent();
					var prev_line = line.prev();
					var tbody = line.parent();
					tbody.addClass('hide');
					line.find('input').val('');					
					line.find('textarea').val('');					
					line.find('select').val('euro');	
					prev_line.find('input').val('');		
					prev_line.find('textarea').val('');					
					prev_line.find('select').val('euro');
                    recalcul_totaux();
					return false;
				});
				
				$(".add_line_product").click(function()
				{
					$(".migc4_main_table_tbody.hide:first").removeClass('hide');
                    recalcul_totaux();
					return false;
				});
				
				
				$("#edit_form_container #migc4_main_table").sortable({stop: function( event, ui )
				{
				    var numero = 1;
					$(".ordby_line").each(function(i)
					{
					  $(this).val(numero);
					  numero++;
					});


				}});
				
				
				$(".recalcul").blur(recalcul_prices);
				$(".recalcul").click(recalcul_prices);
				$(".recalcul").keyup(recalcul_prices);


               if($('.btn_change_listbox').length > 0) {

                   $(".multiple_ .btn_change_listbox,.multiple_0 .btn_change_listbox").click(function () {
                       var me = $(this);
                       var me_id = me.attr('id');
                       var listbox_id = me.attr('rel');
                       var parent = me.parent();

                       // me.toggleClass('btn-info');
                       // me.toggleClass('btn-default');

                       // parent.children('a').removeClass('btn-info').addClass('btn-default');
                       //me.removeClass('btn-default').addClass('btn-info');

                       //var listbox_value = me.attr('id');
                       var values = ',';
                       parent.children('a').each(function (i) {
                           var enfant = $(this);
                           var enfant_id = enfant.attr('id');

                           if (me_id == enfant_id) {
                               //si on est sur l'enfant clique

                               if (enfant.hasClass('btn-info')) {
                                   //s'il est est on -> off = valeur vide
                                   values = '';
                                   enfant.removeClass('btn-info').addClass('btn-default');
                               }
                               else {
                                   //s'il est à off -> valeur = son id
                                   values = enfant.attr('id');
                                   enfant.addClass('btn-info').removeClass('btn-default');
                               }
                           }
                           else {
                               //si on est pas sur l'enfant clique
                               //off
                               enfant.removeClass('btn-info').addClass('btn-default');
                           }
                       });

                       // $('.'+listbox_id).val(listbox_value).change();
                       $('.' + listbox_id).val(values).change();
                       return false;
                   });
               }
				
				jQuery('.qty_line').mask('999999.99');
				jQuery('.pu_line').mask("S999999.99", 
				{
					translation: 
					{
						'S': 
						{
							pattern: /-/,
							optional: true
						}
					}
				});
				jQuery('#delai_paiement').mask('999999.99');
			  
			    var query = '';

				jQuery('.save_fac').click(function()
				{
					
					var donnees = new Object();
					$("textarea.saveme").each(function(i)
				    {
					   donnees[$(this).attr('name')] = $(this).val();
					  
				    });
					$("input.saveme").each(function(i)
				    {
					   donnees[$(this).attr('name')] = $(this).val();
				    });
					$("select.saveme").each(function(i)
				    {
					   donnees[$(this).attr('name')] = $(this).val();
				    });
					donnees['save_fac'] = 'save_fac';
					donnees['sw'] = 'save_doc';

					var request = $.ajax(
				   {
						url: self,
						type: 'POST',
						data: donnees
				   });
				   
				   request.done(function(msg) 
				   {
					   $.bootstrapGrowl('<h4><i class="fa fa-check"></i>Les changements apportés à ce document ont étés sauvegardés.</h4>', { type: 'success',align: 'center',
						width: 'auto',offset: {from: 'top', amount: 20}, delay: 2000});
						get_list_body();			
				   });
				   
				   request.fail(function(jqXHR, textStatus) 
				   {
				   });
				   
				   cancel_edit();
				   
				   return false;
				});

			   jQuery('.toggle_remarque').click(function()
			   {
				   var me = jQuery(this);
				   me.parent().parent().parent().children(".line_remarque").toggleClass('hide');
				   return false;
			   });
			   
			   jQuery('.label_line').keyup(function()
			   {
				   var me = jQuery(this);
				   query = me.val();
				   
				   //show next line
				   me.parent().parent().next().removeClass('hide');
				   
				   var request2 = jQuery.ajax(
					{
						url: "adm_handmade_certigreen_commandes.pl?",
						type: "GET",
						data: 
						{
							sw : 'get_products',
							id_record : id_document,
							prefixe : jQuery('.prefixe').val(),
							query : query
						},
						dataType: "html"
					});

					request2.done(function(msg2) 
					{
						var tr_ligne2 = me.parent().parent().parent().parent();
							
						var bloc_proposition =  tr_ligne2.children(".line_product").children('.facture_articles').children('.cell-value-input').children(".facture_propositions");
						bloc_proposition.html(msg2);
						
						$(document).click(function()
						{
						  jQuery('.facture_propositions').html('');
						});					
						
						jQuery('.invoice_product').click(function(event)
						{
							var product = jQuery(this);
							me.val(product.attr('title'));
							me.next('.ref_line').val(product.attr('id'));
							
							me.parent().parent().parent().children('.facture_pu').children('div').children('input').val(product.attr('data-price'));

							jQuery('.facture_propositions').html('');
							event.stopPropagation();
						});
						jQuery('.zap_products').click(function(event)
						{
							me.val('');
							jQuery('.facture_propositions').html('');
							return false;
						});
					});
					request2.fail(function(jqXHR, textStatus) 
					{
					});
			   });
		   });
			request.fail(function(jqXHR, textStatus) 
		   {
				alert(textStatus);
		   });
	
		});
        e.preventDefault();		
    });
}

function recalcul_prices()
{
	
	var line = $(this).parent().parent().parent();
	var qte = line.children('.facture_qty').children('div').children('input').val();
	var pu = line.children('.facture_pu').children('div').children('input').val();
	var remise = line.children('.facture_remise').children('div').children('.remise_line').val();
	var type = line.children('.facture_remise').children('div').children('.facture_type ').val();
	
	var total = '';
	
	if(remise > 0)
	{
		if(type == 'perc')
		{
			total = qte * pu * ((100 - remise) / 100);
		}
		if(type == 'euro')
		{
			total = ( qte * pu ) - remise;
		}
	}
	else
	{
		total = ( qte * pu );

	}
	
	total = Math.round(total * 100) / 100;




	
	line.children('.facture_pt').children('div').children('input').val(total);

	
	recalcul_totaux();
	return false;
}

function recalcul_totaux()
{
	var total_htva = 0;
	var total_tvac = 0;

	jQuery('.total_line').each(function(i)
	{
		var me = jQuery(this);
		var rel = me.attr('rel');

		var me_htva = parseFloat(me.val());
		var me_tvac = 0;

		if(me_htva > 0) {
            total_htva += me_htva;

            var taux_tva = jQuery('select[name="id_taux_tva_'+rel+'"]').val();
            me_tvac = me_htva;
            me_tvac *= (1 + taux_tva / 100);

            total_tvac += me_tvac;

            console.log(taux_tva);
        }
	});

    total_htva = Math.round(total_htva * 100) / 100;
	jQuery(".total_htva_preview").html(total_htva+' €');

    total_tvac = Math.round(total_tvac * 100) / 100;
	jQuery(".total_tvac_preview").html(total_tvac+' €');
}