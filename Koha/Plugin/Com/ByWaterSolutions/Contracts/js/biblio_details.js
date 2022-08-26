if( $("#catalog_detail").length > 0 ){

    $("#bibliodetails ul").append('<li role="presentation"><a id="contracts_tab_title" href="#contracts" aria-controls="contracts" role="tab" data-toggle="tab">Contracts</a></li>');
    $("#bibliodetails .tab-content").append('<div role="tabpanel" class="tab-pane" id="contracts"><div id="contracts_content"><h3>Contracts</h3></div></div>');
    $("#contracts_content").append('<a href="/cgi-bin/koha/plugins/run.pl?class=Koha%3A%3APlugin%3A%3ACom%3A%3AByWaterSolutions%3A%3AContracts&method=tool&biblionumber='+biblionumber+'" target="popup" onclick="window.open("/cgi-bin/koha/plugins/run.pl?class=Koha%3A%3APlugin%3A%3ACom%3A%3AByWaterSolutions%3A%3AContracts&method=tool&biblionumber='+biblionumber+'"); return false;">Link to contract</a>');

    function add_contract_data(resources){
        $.each(resources,function(index,resource){
            let result = '<tr class="contract_row"><td class="contract"><fieldset>';
            result +=    '<legend>Contract number: ' + resource.permission.contract.contract_number + '</legend>';
            result +=    '<ul>'
            result +=      '<li>';
            result +=        'Copyright holder: ';
            if( resource.permission.contract.copyright_holder ){
                result += '<a href="/cgi-bin/koha/acqui/supplier.pl?booksellerid=';
                result += resource.permission.contract.supplier_id + '" target="_blank">';
                result += resource.permission.contract.copyright_holder.name;
                result += '</a>';
            }
            result +=      '(' + resource.permission.contract.supplier_id + ')';
            result +=      '</li>';
            result +=      '<li>';
            result +=        'Permission type: ' + resource.permission.permission_type;
            result +=      '</li>';
            result +=      '<li>';
            result +=        'Permission code: ' + resource.permission.permission_code;
            result +=      '</li>';
            result +=      '<li>';
            result +=        'Permission date: ' + moment(resource.permission.permission_date).format('LL');
            result +=      '</li>';
            result +=      '<li>';
            result +=        'Form signed: ' + resource.permission.form_signed;
            result +=      '</li>';
            result +=      '<li>';
            result +=        'Note: ' + resource.permission.note;
            result +=      '</li>';
            result +=    '</li>';
            result +=    '</ul>';
            result +=    '</fieldset></td></tr>';
                console.log( result);
            $("#contracts_table").append(result);
        });
    }

    let options = {
        url: '/api/v1/contrib/contracts/resources',
        method: "GET",
        contentType: "application/json",
        headers: { 'x-koha-embed': ["permission.contract.copyright_holder"] },
        data: 'q=[{"me.biblionumber":'+biblionumber+'}]'
    };
    $.ajax(options)
        .then(function(result) {
            $('#contracts_tab_title').text("Contracts (" + result.length + ")");
            if( result.length > 0 ){

                $("#contracts_content").append('<table id="contracts_table">');
                console.log( result );
                add_contract_data( result );
            } else {}
                
        })
        .fail(function(err){
             console.log( _("There was an error fetching the resources") + err.responseText );
        });

}
