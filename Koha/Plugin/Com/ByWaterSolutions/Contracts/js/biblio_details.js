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
            result +=    '<a class="btn btn-default btn-xs manage_resource" data-bs-toggle="modal" data-bs-target="#components_modal" data-contract_id="' + resource.permission.contract_id + '" data-biblio_id="' + resource.biblionumber + '" data-resource_id="' + resource.resource_id + '" data-permission_id="'+resource.permission.permission_id +'">Manage contracts for issues/analytics</a>';
            result +=    '</fieldset></td></tr>';
            $("#contracts_table").append(result);
        });
    }

    $("body").on('click', '.delete_resource',function() {
            if( window.confirm('Do you want to delete this resource?') ){
                delete_resource( this );
            }
    });
    
    $('#select_all').on('click' , function(e) {
        e.preventDefault();
        $("input.resource_info").each(function() {
            if ($(this).prop("checked") == false) {
              $(this).prop("checked", true).change();
            }
        });
    });

    $('#select_all_linked').on('click' , function(e) {
        e.preventDefault();
        $("input.resource_info").each(function() {
            let linked = $(this).closest('tr').find('.linked').length;
            if ($(this).prop("checked") == false && linked ) {
              $(this).prop("checked", true).change();
            }
        });
    });

    $('#select_all_unlinked').on('click' , function(e) {
        e.preventDefault();
        $("input.resource_info").each(function() {
            let unlinked = $(this).closest('tr').find('.unlinked').length;
            if ($(this).prop("checked") == false && unlinked ) {
              $(this).prop("checked", true).change();
            }
        });
    });

    $('#clear_all').on('click' , function(e) {
        e.preventDefault();
        $("input.resource_info").each(function() {
            if ($(this).prop("checked") == true) {
              $(this).prop("checked", false).change();
            }
        });
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
        var resource_id = button.data('resource_id');
        var permission_id = button.data('permission_id');
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
                            <td><input class="resource_info" type="checkbox" data-resource_id="${resource_id}" data-biblio_id="${part.related_id}" data-permission_id="${permission_id}" /></td>
                            <td>${part.related_id}</td>
                            <td>${part.related_title}</td>
                            <td>${part.relationship_type}</td>
                            <td class="contract-status-${part.related_id}"><p class="loader"><i class="fa fa-spinner fa-spin" style="font-size:24px;color:gray;"></i></p></td>
                        </tr>
                    `);
                    checkComponentContract(part.related_id, contract_id, permission_id).then(isLinked => {
                        const statusCell = $(`.contract-status-${part.related_id}`);
                        if (isLinked) {
                            statusCell.html(`<span class="resource_id linked badge bg-success" data-resource-id="${isLinked.resource_id}">Yes</span>`);
                        } else {
                            statusCell.html(`<span class="resource_id unlinked badge bg-danger">No</span>`);
                        }
                    });
                });
            }
        });
    });

    async function checkComponentContract(biblionumber, currentContractId, currentPermissionId) {
        try {
            let allResources = [];
            let page = 1;
            let hasMore = true;

            while (hasMore) {
                const permissionQuery = encodeURIComponent(`{"permission_id":"${currentPermissionId}"}`);
                const resourcesResponse = await fetch(`/api/v1/contrib/contracts/resources?q=${permissionQuery}&_page=${page}&_per_page=1000`);

                if (resourcesResponse.ok) {
                    const resources = await resourcesResponse.json();
                    allResources = allResources.concat(resources);

                    // Check if we got fewer results than the page size (last page)
                    if (resources.length < 1000) {
                        hasMore = false;
                    } else {
                        page++;
                    }
                } else {
                    hasMore = false;
                }
            }

            const foundResources = allResources.filter(resource => resource.biblionumber == biblionumber);
            if (foundResources.length > 0) {
                return foundResources;
            }

            return null;
        } catch (error) {
            console.error(`Error checking contract for biblio ${biblionumber}:`, error);
            return null;
        }
    }

    $('.unlinkfromcontract').on('click', function() {
        $('.problem').empty();
        const deletePromises = [];
        let checked_count = $('.resource_info:checked').length;
        if (checked_count === 0) {
            alert('No resources selected.');
            return;
        }

        if (!confirm(`Are you sure you want to unlink ${checked_count} resource${checked_count > 1 ? 's' : ''} from this contract?`)) {
            return;
        }
        
        $('#component_modal_results tbody tr').each(function() {
            let row = $(this);
            const checkbox = $(this).find('input[type="checkbox"]');
            let unlinked = row.find('.unlinked').length;
            if ( checkbox.is(':checked') && unlinked ) {
                $('<div class="hint problem">Already unlinked</span>').insertAfter( row.find('.badge') );
            }
            if (checkbox.is(':checked') && !unlinked ) {
                $('<p class="loader"><i class="fa fa-spinner fa-spin" style="font-size:24px;color:gray;"></i></p>').insertAfter( row.find('.badge') )
                row.find('.badge').hide();
                let resource_id = row.find('.resource_id').data('resource-id'); 
                if (resource_id) {
                    const deletePromise = $.ajax({
                        url: '/api/v1/contrib/contracts/resources/' + resource_id,
                        method: "DELETE",
                        contentType: "application/json",
                    }).then(function(result) {
                        row.find('.loader').hide();
                        row.find('.badge').replaceWith(`<span class="resource_id unlinked badge bg-danger" data-resource-id="">No</span>`);
                        row.find('.badge').show();
                        checkbox.prop('checked', false);
                    });
                    
                    deletePromises.push(deletePromise);
                }
            }
        });
        
        Promise.all(deletePromises).then(function() {
            console.log('All unlinking completed');
        }).catch(function(error) {
            console.error('Some unlinking failed:', error);
        });
    });

    $('.linktocontract').on('click', function() {
        $('.problem').empty();
        const addPromises = [];
        let checked_count = $('.resource_info:checked').length;
        if (checked_count === 0) {
            alert('No linked resources selected.');
            return;
        }

        if (!confirm(`Are you sure you want to link ${checked_count} resource${checked_count > 1 ? 's' : ''} to this contract?`)) {
            return;
        }

        $('#component_modal_results tbody tr').each(function() {
            let row = $(this);
            const checkbox = row.find('input[type="checkbox"]');
            let linked = row.find('.linked').length;
            if ( checkbox.is(':checked') && linked ) {
                $('<div class="hint problem">Already linked</span>').insertAfter( row.find('.badge') );
            }

            if (checkbox.is(':checked') && !linked ) {
                $('<p class="loader"><i class="fa fa-spinner fa-spin" style="font-size:24px;color:gray;"></i></p>').insertAfter( row.find('.badge') )
                row.find('.badge').hide();
                let biblio_id = row.find('.resource_info').data('biblio_id');
                let permission_id = row.find('.resource_info').data('permission_id');
                let resource_id = row.find('.resource_info').data('resource_id');

                const postData = {
                    biblionumber: biblio_id,
                    permission_id: permission_id,
                };

                const addPromise = $.ajax({
                    url: '/api/v1/contrib/contracts/resources/',
                    method: "POST",
                    contentType: "application/json",
                    data: JSON.stringify(postData)
                }).then(function(result) {
                    row.find('.loader').hide();
                    row.find('.badge').replaceWith(`<span class="resource_id linked badge bg-success" data-resource-id="${result.resource_id}">Yes</span>`);
                    row.find('.badge').show();
                    checkbox.prop('checked', false);
                    
                });

                addPromises.push(addPromise);
            }
        });

        Promise.all(addPromises).then(function() {
            console.log('All linking completed');
        }).catch(function(error) {
            console.error('Some linking failed:', error);
        });
    });
}
