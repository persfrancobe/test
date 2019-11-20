var self='';

/*
 MIT License {@link http://creativecommons.org/licenses/MIT/}
 MIT License {@link http://creativecommons.org/licenses/MIT/}
*/




$(document).ready(function() 
{
    init_tinymce();
});
 
 

function init_tinymce()
{
	//ohSnap('Texte sauvegardé', 'green');
	//TITRES DE PARAGRAPHES
	tinymce.init({
			selector: ".mig_parag_title_content",
			inline: true,
			language : 'fr_FR',
			toolbar: "undo redo | save",
			plugins: 
			[
				"save  "
			],
			menubar: false,
		save_enablewhendirty: true,
		save_onsavecallback: save_mig_parag_content,
		
	});
	//PARAGRAPHES
	tinymce.init({
			selector: ".mig_parag_content",
			inline: true,
			language : 'fr_FR',
			toolbar: "undo redo | bold italic | forecolor backcolor | save",
			plugins: 
			[
				"save textcolor "
			],
			menubar: false,
		save_enablewhendirty: true,
		save_onsavecallback: save_mig_parag_content,
		
	});
}

function save_mig_parag_content()
{
	var id_editor = jQuery(this).attr('id');
	var editor = jQuery("#"+id_editor);
	var content = editor.html();
	var idcontent = editor.data('idcontent');
	var lg = editor.data('lg');
	var self = '/cgi-bin/migcms_view.pl?';
	
	ohSnap('Texte sauvegardé', 'green');
	
	jQuery.ajax(
	{
		 type: "POST",
		 url: self,
		 data: "&sw=save_mig_parag_content&lg="+lg+"&id="+idcontent+"&content="+encodeURIComponent(content),
		 success: function(msg)
		 {
		 
		 
		 }
	});
}
 

