if( $("#catalog_detail").length > 0 ){

    $("#bibliodetails ul").append('<li class="nav-item" role="presentation"><a id="contracts_tab_title" class="nav-link" href="#contracts_panel" aria-controls="contracts" role="tab" data-bs-toggle="tab">Contracts</a></li>');
    $("#bibliodetails .tab-content").append('<div role="tabpanel" class="tab-pane" id="contracts_panel"><div id="contracts_content"><h3>Contracts</h3></div></div>');
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
            result +=        'Form signed: ' + (resource.permission.form_signed ? "Yes" : "0");
            result +=      '</li>';
            result +=      '<li>';
            result +=        'Note: ' + resource.permission.note;
            result +=      '</li>';
            result +=      '<li>';
            result +=        'RVN: ' + resource.permission.contract.rvn;
            result +=      '</li>';
            result +=    '</li>';
            result +=    '</ul>';
            result +=    '<a class="btn btn-default btn-xs delete_resource" data-resource_id="' + resource.resource_id + '">Unlink contract</a>';
            result +=    '<a class="btn btn-default btn-xs manage_resource" data-bs-toggle="modal" data-bs-target="#components_modal" data-contract_id="' + resource.permission.contract_id + '" data-biblio_id="' + resource.biblionumber + '">Manage contracts for issues/analytics</a>';
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

    $('#components_modal').on('shown.bs.modal', function (e) {
        var button = $(e.relatedTarget);
        var biblio_id = button.data('biblio_id');
        var contract_id = button.data('contract_id');
        var url = '/api/v1/contrib/contracts/biblios/'+ biblio_id  +'/components';
        $.ajax({
            type: "GET",
            url: url,
            contentType: "application/json",
            complete: function(data) {
                $('#components_modal .modal-body table tbody').empty();
                let response = data.responseJSON;
                response.forEach( function(part) {
                    $('#components_modal .modal-body table tbody').append(`
                        <tr>
                            <td><input type="checkbox" value="${contract_id}" /></td>
                            <td>${part.related_id}</td>
                            <td>${part.related_title}</td>
                            <td>${part.relationship_type}</td>
                            <td class="contract-status-${part.related_id}"></td>
                        </tr>
                    `);
                    // Check if this component has a contract
                    checkComponentContract(part.related_id, contract_id).then(isLinked => {
                        const statusCell = $(`.contract-status-${part.related_id}`);
                        if (isLinked) {
                            statusCell.html(`<span class="badge bg-success">Yes</span>`);
                        } else {
                            statusCell.html(`<span class="badge bg-danger">No</span>`);
                        }
                    });
                });
            }
        });
    });

    async function checkComponentContract(biblionumber, currentContractId) {
        try {
            const permissionsQuery = encodeURIComponent(`{"contract_id":"${currentContractId}"}`);
            const permissionsResponse = await fetch(`/api/v1/contrib/contracts/permissions?q=${permissionsQuery}`);
            
            if (!permissionsResponse.ok) {
                return false;
            }
            
            const permissions = await permissionsResponse.json();
            
            for (let permission of permissions) {
                const resourcesQuery = encodeURIComponent(`{"permission_id":"${permission.permission_id}"}`);
                const resourcesResponse = await fetch(`/api/v1/contrib/contracts/resources?q=${resourcesQuery}`);
                
                if (resourcesResponse.ok) {
                    const resources = await resourcesResponse.json();
                    const foundResource = resources.find(resource => resource.biblionumber == biblionumber);
                    if (foundResource) {
                        return true;
                    }
                }
            }
            
            return false;
        } catch (error) {
            console.error(`Error checking contract for biblio ${biblionumber}:`, error);
            return false;
        }
    }


}
