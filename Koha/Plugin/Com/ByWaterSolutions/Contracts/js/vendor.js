// vendor.js - Complete version with all contract details

(function() {
    'use strict';
    
    // Only run on vendor pages
    if (!window.location.pathname.match(/\/acquisition\/vendors\/\d+/)) return;
    
    // Get vendor ID
    const match = window.location.pathname.match(/\/acquisition\/vendors\/(\d+)/);
    const vendorId = match ? match[1] : null;
    if (!vendorId) return;
    
    // When page loads, fetch and display
    window.addEventListener('load', function() {
        fetch('/api/v1/contrib/contracts/contracts?q=[{"supplier_id":' + vendorId + '}]', {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json',
                'x-koha-embed': 'permissions.resources.biblio,copyright_holder'
            }
        })
        .then(r => r.json())
        .then(contracts => {
            if (contracts.length === 0) return;
            
            let html = '<div id="vendor_contracts" class="offset-md-2"><h3>Contracts (' + contracts.length + ')</h3><table id="contracts_table"><tbody>';
            
            contracts.forEach(contract => {
                html += '<tr><td class="contract"><fieldset>';
                html += '<legend>Contract number: ' + contract.contract_number + '</legend>';
                html += '<ul>';
                html += '<li>Copyright holder: ';
                if (contract.copyright_holder) {
                    html += contract.copyright_holder.name;
                }
                html += ' (' + contract.supplier_id + ')';
                html += '</li>';
                
                contract.permissions.forEach(permission => {
                    html += '<li>Permission number: ' + permission.permission_id + '</li>';
                    html += '<li>Permission type: ' + permission.permission_type + '</li>';
                    html += '<li>Permission code: ' + permission.permission_code + '</li>';
                    html += '<li>Permission date: ' + (permission.permission_date || '') + '</li>';
                    html += '<li>Form signed: ' + (permission.form_signed ? 'Yes' : 'No') + '</li>';
                    html += '<li>Note: ' + (permission.note || '') + '</li>';
                    
                    if (permission.resources) {
                        permission.resources.forEach(resource => {
                            html += '<li>Resource: (' + resource.biblionumber + ') ';
                            if (resource.biblio) {
                                html += '<a href="/cgi-bin/koha/catalogue/detail.pl?biblionumber=' + resource.biblionumber + '" target="_blank">';
                                html += resource.biblio.title;
                                html += '</a>';
                            }
                            html += '</li>';
                        });
                    }
                });
                
                html += '</ul>';
                html += '</fieldset></td></tr>';
            });
            
            html += '</tbody></table></div>';
            
            document.body.insertAdjacentHTML('beforeend', html);
        });
    });
})();
