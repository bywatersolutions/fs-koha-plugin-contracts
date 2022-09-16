$.getScript("/intranet-tmpl/lib/moment/moment.min.js");

if( $("#acq_supplier").length > 0 ){

    let getUrlParameter = function getUrlParameter(sParam) {
    let sPageURL = window.location.search.substring(1),
            sURLVariables = sPageURL.split('&'),
            sParameterName,
            i;
        for (i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split('=');
            if (sParameterName[0] === sParam) {
                return sParameterName[1] === undefined ? true : decodeURIComponent(sParameterName[1]);
            }
        }
	};
    $("main").append('<div id="vendor_contracts"></div>');
    function add_contract_data(contracts){
        $.each(contracts,function(index,contract){
            let result = '<tr><td class="contract"><fieldset>';
            result +=    '<legend>Contract number: ' + contract.contract_number + '</legend>';
            result +=    '<ul>'
            result +=      '<li>';
            result +=        'Copyright holder: ';
            if( contract.copyright_holder ){
                result += contract.copyright_holder.name;
            }
            result +=      '(' + contract.supplier_id + ')';
            result +=      '</li>';
            $.each(contract.permissions,function(index,permission){
                result +=      '<li>';
                result +=        'Permission number: ' + permission.permission_id;
                result +=      '</li>';
                result +=      '<li>';
                result +=        'Permission type: ' + permission.permission_type;
                result +=      '</li>';
                result +=      '<li>';
                result +=        'Permission code: ' + permission.permission_code;
                result +=      '</li>';
                result +=      '<li>';
                result +=        'Permission date: ' + moment(permission.permission_date).format('LL');
                result +=      '</li>';
                result +=      '<li>';
                result +=        'Form signed: ' + permission.form_signed;
                result +=      '</li>';
                result +=      '<li>';
                result +=        'Note: ' + permission.note;
                result +=      '</li>';
                $.each(permission.resources,function(index,resource){
                    result +=      '<li>';
                    result +=        'Resource: (' + resource.biblionumber + ') ';
                    if( resource.biblio ){
                        result += '<a href="/cgi-bin/koha/catalogue/detail.pl?biblionumber='
                        result += resource.biblionumber+'" target="_blank">';
                        result += resource.biblio.title;
                        result += '</a>';
                    }
                    result +=      '</li>';
                });
            });
            result +=    '</ul>';
            result +=    '</fieldset></td></tr>';
            $("#contracts_table").append(result);
        });
    }
    let vendor_id = getUrlParameter('booksellerid');
    console.log(vendor_id);
    let options = {
        url: '/api/v1/contrib/contracts/contracts',
        method: "GET",
        contentType: "application/json",
        headers: { 'x-koha-embed': ["permissions.resources.biblio","copyright_holder"] },
        data: 'q=[{"supplier_id":'+vendor_id+'}]'
    };
    $.ajax(options)
        .then(function(result) {
            $('#contracts_tab_title').text("Contracts (" + result.length + ")");
            if( result.length > 0 ){

                $("#vendor_contracts").append('<table id="contracts_table">');
                console.log( result );
                add_contract_data( result );
            } else {}
                
        })
        .fail(function(err){
             console.log( _("There was an error fetching the resources") + err.responseText );
        });

}
