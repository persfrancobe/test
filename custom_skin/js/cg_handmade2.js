function replaceOldCheckboxWithNewButton() {

    //remplace toules les checkboxes par des boutons bootstrap
    $(".replaceOldCheckboxWithNewButton").each(function (i) {
        var this_cb = $(this);
        var this_cb_id = $(this).attr('id');
        var this_parent = $(this).parent();
        var this_cb_label = this_cb.next('label');
        var this_cb_label_txt = this_cb_label.html();

        this_cb_label.hide();
        this_cb.hide();
        if(this_cb.attr('checked'))
        {
            this_parent.append('<a href="#" class="btn btn-info toggle_mig_link_button" data-target="' + this_cb_id + '">' + this_cb_label_txt + '<a/>');
        }
        else
        {
            this_parent.append('<a href="#" class="btn btn-default toggle_mig_link_button" data-target="' + this_cb_id + '">' + this_cb_label_txt + '<a/>');
        }

    });

    //lie les anciennes cb et les nouveaux boutons
    $(".toggle_mig_link_button").click(function () {
        var this_button = $(this);
        var this_button_id = $(this).attr('data-target');

        if (this_button.hasClass('btn-default')) {
            this_button.removeClass('btn-default').addClass('btn-info');
            $('#' + this_button_id).prop('checked', true);
        }
        else {
            this_button.addClass('btn-default').removeClass('btn-info');
            $('#' + this_button_id).prop('checked', false);
        }
        return false;
    });
}


function replaceOldListboxesWithNewButtons() {

    //remplace toules les optins de LA select par des boutons (limitation à 1 select)
    $(".mig_listbox_to_buttons option").each(function (i) {
        var this_option = $(this);
        var this_option_value = $(this).attr('value');
        var this_parent = $(this).parent().parent();
        var this_option_label = this_option.html();

        $(".mig_listbox_to_buttons").hide();

        if($(this).parent().val() == this_option_value)
        {
            this_parent.append('<a href="#" class="btn btn-info set_select_mig_link_button" data-target="' + this_option_value + '">' + this_option_label + '<a/>');
        }
        else
        {
            this_parent.append('<a href="#" class="btn btn-default set_select_mig_link_button" data-target="' + this_option_value + '">' + this_option_label + '<a/>');
        }

    });

    //lie les anciennes cb et les nouveaux boutons
    $(".set_select_mig_link_button").click(function () {

        var this_button = $(this);
        var this_button_id = $(this).attr('data-target');

        if (this_button.hasClass('btn-default')) {

            $(".set_select_mig_link_button.btn-info").removeClass('btn-info').addClass('btn-default');

            this_button.removeClass('btn-default').addClass('btn-info');
            $(".mig_listbox_to_buttons").val(this_button_id);
        }
        else {
            // this_button.addClass('btn-default').removeClass('btn-info');
            // $(".mig_listbox_to_buttons").val('');
        }
        return false;
    });
}


function replaceOldCheckboxesWithNewButtons() {

    //remplace toules les checkboxes par des boutons bootstrap
    $(".mig_link_to_buttons input").each(function (i) {
        var this_cb = $(this);
        var this_cb_id = $(this).attr('id');
        var this_parent = $(this).parent();
        var this_cb_label = this_cb.next('label');
        var this_cb_label_txt = this_cb_label.html();

        // this_cb_label.hide();
        // this_cb.hide();

        this_parent.append('<a href="#" class="btn btn-default toggle_mig_link_button" data-target="' + this_cb_id + '">' + this_cb_label_txt + '<a/>');
    });

    //lie les anciennes cb et les nouveaux boutons
    $(".toggle_mig_link_button").click(function () {
        var this_button = $(this);
        var this_button_id = $(this).attr('data-target');

        if (this_button.hasClass('btn-default')) {
            this_button.removeClass('btn-default').addClass('btn-info');
            $('#' + this_button_id).prop('checked', true);
        }
        else {
            this_button.addClass('btn-default').removeClass('btn-info');
            $('#' + this_button_id).prop('checked', false);
        }
        return false;
    });
}

function init_commande_copy_fields()
{
    jQuery(document).on("click", "#recopier_bien_client", function()
    {
        jQuery("#step2_form_street").val(jQuery("#step2_form_adresseRue").val());
        jQuery("#step2_form_number").val(jQuery("#step2_form_adresseNumero").val());
        jQuery("#step2_form_zip").val(jQuery("#step2_form_adresseCp").val());
        jQuery("#step2_form_city").val(jQuery("#step2_form_adresseVille").val());
        return false;
    });

    jQuery(document).on("click", "#recopier_client_facturation", function()
    {
        //jQuery("#field_facture_societe_nom").val(jQuery("#field_societe_nom").val());
        jQuery("#step2_form_factureNom").val(jQuery("#step2_form_lastname").val());
        jQuery("#step2_form_facturePrenom").val(jQuery("#step2_form_firstname").val());
        jQuery("#step2_form_factureStreet").val(jQuery("#step2_form_street").val());
        jQuery("#step2_form_factureNumber").val(jQuery("#step2_form_number").val());
        jQuery("#step2_form_factureZip").val(jQuery("#step2_form_zip").val());
        jQuery("#step2_form_factureCity").val(jQuery("#step2_form_city").val());
        jQuery("#step2_form_factureEmail").val(jQuery("#step2_form_email").val());
        return false;
    });
}