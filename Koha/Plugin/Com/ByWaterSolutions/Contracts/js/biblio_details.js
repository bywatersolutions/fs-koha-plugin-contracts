if( $("#catalog_detail").length > 0 ){

    $("#bibliodetails ul").append('<li role="presentation"><a id="contracts_tab_title" href="#contracts" aria-controls="contracts" role="tab" data-toggle="tab">Contracts</a></li>');
    $("#bibliodetails .tab-content").append('<div role="tabpanel" class="tab-pane" id="contracts"><div id="contracts_content"><h3>Contracts</h3></div></div>');
    $("#contracts_content").append('<a href="/cgi-bin/koha/plugins/run.pl?class=Koha%3A%3APlugin%3A%3ACom%3A%3AByWaterSolutions%3A%3AContracts&method=tool&biblionumber='+biblionumber+'" target="_blank" >Link to contract</a>');

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
            result +=        'Permission number: ' + resource.permission.permission_id;
            result +=      '</li>';
            result +=      '<li>';
            result +=        'Permission type: ' + resource.permission.permission_type;
            result +=      '</li>';
            result +=      '<li>';
            result +=        'Permission code: ' + resource.permission.permission_code;
            result +=      '</li>';
            result +=      '<li>';
            result +=        'Permission date: ' + dayjs(resource.permission.permission_date).format('MMMM DD, YYYY');
            result +=      '</li>';
            result +=      '<li>';
            result +=        'Form signed: ' + resource.permission.form_signed;
            result +=      '</li>';
            result +=      '<li>';
            result +=        'Note: ' + resource.permission.note;
            result +=      '</li>';
            result +=    '</li>';
            result +=    '</ul>';
            result +=    '<a class="btn btn-default btn-xs delete_resource" data-resource_id="' + resource.resource_id + '">Unlink contract</a>';
            result +=    '</fieldset></td></tr>';
            $("#contracts_table").append(result);
        });
    }
    $("body").on('click', '.delete_resource',function() {
            if( window.confirm('Do you want to delete this resource?') ){
                delete_resource( this );
            }
    });

    function delete_resource( the_button ){
        let resource_id = $( the_button ).data('resource_id');
        let options = {
            url: '/api/v1/contrib/contracts/resources/' + resource_id,
            method: "DELETE",
            contentType: "application/json",
        };
        $.ajax(options)
            .then(function(result) {
                alert( "Permission successfully deleted.");
                $(the_button).closest('tr').remove();
            })
            .fail(function(err) {
                alert("There was an error during deletion:" + err.responseText );
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
                add_contract_data( result );
            } else {}
                
        })
        .fail(function(err){
             console.log( _("There was an error fetching the resources") + err.responseText );
        });

}
