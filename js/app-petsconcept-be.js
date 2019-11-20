$(document).ready(function()
{
    initScanArea();
});

function initScanArea()
{
    //test si page de scan
    if(!($("#scanArea").length))
    {
      return '';
    }

    //chargement des deux listes produits et scans
    refreshListOrderDetails();
    refreshListScans();

    //focus sur la zone
    $("#beginScan").on('click', function(e) {

        $("#scanArea").focus();
        e.preventDefault();
    });

    $("#scanArea").val('');

    //ecouteur zone de scan
    var bc = '';
    $("#scanArea").keydown(function(event)
    {
        console.log(event);
        if(event.key != 'Control' && event.key != 'b' && event.key != 'Enter')
        {
            bc+=event.key;
        }

        $("#log").append('KEY:['+event.which+']');
        $("#log").append('bc:['+bc+']');
        if(event.which == 13)
        {
            $("#log").append('-ENTER KEY-');
            send_barcode(bc);

            //empty scan area
            bc = '';
            $("#scanArea").val('');
            $("#log").append('EMPTY SCAN');
        }
    });
}

function send_barcode(letters)
{
    //get scan value
    $("#log").append('letters:['+letters+']');

    //letters -> barcode
    letters = letters.replace(new RegExp(/&/, 'gi'), '1');
    letters = letters.replace(new RegExp(/é/, 'gi'), '2');
    letters = letters.replace(new RegExp(/\"/, 'gi'), '3');
    letters = letters.replace(new RegExp(/\'/, 'gi'), '4');
    letters = letters.replace(new RegExp(/\(/, 'gi'), '5');
    letters = letters.replace(new RegExp(/\§/, 'gi'), '6');
    letters = letters.replace(new RegExp(/è/, 'gi'), '7');
    letters = letters.replace(new RegExp(/!/, 'gi'), '8');
    letters = letters.replace(new RegExp(/ç/, 'gi'), '9');
    letters = letters.replace(new RegExp(/à/, 'gi'), '0');

    letters = letters.replace(new RegExp(/d/, 'gi'), '');
    letters = letters.replace(new RegExp(/c/, 'gi'), '');
    var barcode = letters;
    $("#log").append('letters2:['+letters+']');
    $("#log").append('send barcode:['+barcode+']');

    //send barcode
    var url = '/ajax-scan/'+$("#listOrderDetails").attr('data-idorder')+'/'+barcode;

    $.ajax({
        url: url,
        dataType: 'json',
        async: false,
        success: function(data) {
            $("#log").append('barcode_valid:['+data.barcode_valid+']');
            $("#log").append('barcode_full:['+data.barcode_full+']');
            //if barcode ! valid
            if(data.barcode_valid == 0) {
                $("#error_alert").removeClass('d-none');
                $("#valid_alert").addClass('d-none');
                $("#error_msg").html("Code barre " + data.barcode_value + " inconnu pour la commande " + data.order_id);
            }
            else if(data.barcode_full == 1){
                $("#error_alert").removeClass('d-none');
                $("#valid_alert").addClass('d-none');
                $("#error_msg").html("Code barre " + data.barcode_value + " déjà scanné pour la commande " + data.order_id);
            }
            else if(data.insert_scan == 1){
                $("#error_alert").addClass('d-none');
                $("#valid_alert").removeClass('d-none');
                $("#valid_msg").html("Code barre " + data.barcode_value + " OK ");
                refreshListOrderDetails();
                refreshListScans();
            }


        }
    });
}

function refreshListOrderDetails()
{
    var self_script = '/ajax-lines-commande/'+$("#listOrderDetails").attr('data-idorder');
    var request = $.ajax(
        {
            url: self_script,
            type: "GET",
            dataType: "html",
            cache: false
        });

    request.done(function(msg)
    {
        $("#listOrderDetails").html(msg);
    });
    request.fail(function(jqXHR, textStatus)
    {
        $("#listOrderDetails").html('Erreur de chargement');
    });
}

function refreshListScans()
{
    var self_script = '/ajax-lines-scan/'+$("#listScans").attr('data-idorder');
    var request = $.ajax(
        {
            url: self_script,
            type: "GET",
            dataType: "html",
            cache: false
        });

    request.done(function(msg)
    {
        $("#listScans").html(msg);
    });
    request.fail(function(jqXHR, textStatus)
    {
        $("#listScans").html('Erreur de chargement');
    });
}