package Koha::Plugin::Com::ByWaterSolutions::Contracts;

use Modern::Perl;

use C4::Installer qw(TableExists);

use JSON qw(decode_json);

use base qw(Koha::Plugins::Base);

## Here we set our plugin version
our $VERSION         = "{VERSION}";
our $MINIMUM_VERSION = "21.11.00";

## Here is our metadata, some keys are required, some are optional
our $metadata = {
    name            => 'Contracts Plugin',
    author          => 'Nick Clemens',
    date_authored   => '2022-06-29',
    date_updated    => "1900-01-01",
    minimum_version => $MINIMUM_VERSION,
    maximum_version => undef,
    version         => $VERSION,
    description =>
      'This plugin adds the ability to manage contract permissions in Koha.',
};

use Module::Metadata;
use Koha::Schema;
BEGIN {
    my $path = Module::Metadata->find_module_by_name(__PACKAGE__);
    $path =~ s!\.pm$!/lib!;
    unshift @INC, $path;

    require Koha::Schema::Result::KohaPluginComBywatersolutionsContractsContract;
    require Koha::Schema::Result::KohaPluginComBywatersolutionsContractsPermission;
    require Koha::Schema::Result::KohaPluginComBywatersolutionsContractsResource;
    require Koha::Contracts;
    require Koha::ContractPermissions;


    # register the additional schema classes
    Koha::Schema->register_class(KohaPluginComBywatersolutionsContractsContract => 'Koha::Schema::Result::KohaPluginComBywatersolutionsContractsContract');
    Koha::Schema->register_class(KohaPluginComBywatersolutionsContractsContractPermission => 'Koha::Schema::Result::KohaPluginComBywatersolutionsContractsPermission');
    Koha::Schema->register_class(KohaPluginComBywatersolutionsContractsContractResource => 'Koha::Schema::Result::KohaPluginComBywatersolutionsContractsResource');
    # force a refresh of the database handle so that it includes the new classes
    Koha::Database->schema({ new => 1 });
}


sub new {
    my ( $class, $args ) = @_;

    ## We need to add our metadata here so our base class can access it
    $args->{'metadata'} = $metadata;
    $args->{'metadata'}->{'class'} = $class;

    ## Here, we call the 'new' method for our base class
    ## This runs some additional magic and checking
    ## and returns our actual $self
    my $self = $class->SUPER::new($args);

    return $self;
}

sub install {
    my ( $self, $args ) = @_;

    my $contracts_table = $self->get_qualified_table_name('contracts');
    unless( TableExists( $contracts_table ) ){
        C4::Context->dbh->do( "
            CREATE TABLE `$contracts_table` (
                contract_id INT(10) NOT NULL AUTO_INCREMENT,
                supplier_id INT(10) NULL,
                contract_number VARCHAR(255),
                created_on timestamp NOT NULL DEFAULT current_timestamp(),
                created_user INT(11) NOT NULL,
                updated_on timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
                updated_user INT(11) NOT NULL,
                PRIMARY KEY (`contract_id`),
                CONSTRAINT `contracts_plugin_contracts_ibfk_1` FOREIGN KEY (`supplier_id`) REFERENCES `aqbooksellers` (`id`)
            ) ENGINE = INNODB;
        " );
    }
    my $permissions_table = $self->get_qualified_table_name('permissions');
    unless( TableExists( $permissions_table ) ){
        C4::Context->dbh->do( "
            CREATE TABLE $permissions_table (
                permission_id INT(10) NOT NULL AUTO_INCREMENT,
                contract_id INT( 10 ) NULL,
                permission_type VARCHAR(255) NOT NULL,
                permission_code VARCHAR(255) NOT NULL,
                permission_date datetime NOT NULL DEFAULT current_timestamp(),
                form_signed TINYINT(1),
                note longtext COLLATE utf8mb4_unicode_ci,
                PRIMARY KEY (`permission_id`),
                CONSTRAINT `contracts_plugin_permissions_ibfk_1` FOREIGN KEY (`contract_id`) REFERENCES `$contracts_table` (`contract_id`)
            ) ENGINE = INNODB;
        " );
    }
    my $resources_table = $self->get_qualified_table_name('resources');
    unless( TableExists( $resources_table ) ){
        C4::Context->dbh->do( "
            CREATE TABLE $resources_table (
                resource_id INT(10) NOT NULL AUTO_INCREMENT,
                permission_id INT( 10 ) NULL,
                biblionumber INT(10) NOT NULL,
                PRIMARY KEY (`resource_id`),
                CONSTRAINT `contracts_plugin_resources_ibfk_1` FOREIGN KEY (`permission_id`) REFERENCES `$permissions_table` (`permission_id`)
            ) ENGINE = INNODB;
        " );
    }

    return 1;
}

sub tool {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    $self->tool_step_1();
}

sub tool_step_1 {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $template = $self->get_template({ file => 'contracts.tt' });
    my $count = Koha::Contracts->search()->count;
    $template->param( contracts_count => $count );
    print $cgi->header();
    print $template->output();
}

sub upgrade {
    my ( $self, $args ) = @_;

    return 1;
}

sub uninstall() {
    my ( $self, $args ) = @_;

    return 1;
}

sub intranet_head {
    my ( $self ) =@_;

    return q|
        <style>
            #contract_modal_results {
                display: flex;
                flex-direction: column;
            }
            #contract_results {
                font-weight: 700;
                padding-left: 1em;
            }
            .contract_result_bottom {
                border-bottom: 1px solid #000;
            }
            .contract_result_bottom td {
                padding-bottom: 10px;
            }
        </style>
        <div id="contract_modal" class="modal" tabindex="-1" role="dialog" aria-hidden="true">
            <div class="modal-dialog modal-lg">
                <div class="modal-content">
                    <div class="modal-header">
                        <button type="button" class="closebtn" data-dismiss="modal" aria-label="Close">x</button>
                        <h3 class="modal-title">Contract Info</h3>
                    </div>
                    <div class="modal-body">
                        <table id="contract_modal_results" class="table">
                        </table>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                    </div>
                </div>
            </div>
        </div>
    |;
}

sub intranet_js {
    my ( $self ) = @_;

    return q|
    let contract = {
      "Permission_Code": "A1 B1a C1 D2 E1 F1 G2 H2 I1 J1 K1",
      "Permission_type": "Permission Granted",
      "Copyright_holder": "Grant, Fred T.",
      "Supplier_code": "18B3A",
      "Contract_number": "7300-041848/1",
      "Permission_number": "5",
      "Permission_date": "11/26/2000",
      "Note": "This is a note",
      "Form_signed": "N",
      "Title_number": "987196"
    };


    function add_contract_modal(contracts){
        $.each(contracts,function(index,value){
            let result = '<tr class="contract">';
            result += '<td><ul>'
            result +=      '<li>';
            result +=        'Permission code:' + contract.Permission_Code;
            result +=      '</li>';
            result +=      '<li>';
            result +=        'Permission type:' + contract.Permission_type;
            result +=      '</li>';
            result +=      '<li>';
            result +=        'Copyright holder:' + contract.Copyright_holder;
            result +=      '</li>';
          result +=      '<li>';
            result +=        'Supplier code:' + contract.Supplier_code;
            result +=      '</li>';
            result +=      '<li>';
            result +=        'Contract number:' + contract.Contract_number;
            result +=      '</li>';
            result +=      '<li>';
            result +=        'Permission number:' + contract.Permission_number;
            result +=      '</li>';
            result +=      '<li>';
            result +=        'Permission date:' + contract.Permission_date;
            result +=      '</li>';
            result +=      '<li>';
            result +=        'Note:' + contract.Note;
            result +=      '</li>';
            result +=    '</li>';
            result +=    '</ul></td>';
            result +=    '</tr>';
            result +=    '<tr class="contract_page contract_result_bottom">';
            result +=      '<td colspan="2" class="contract_details_'+value.titleId+'">';
            result +=      '</td>';
            result +=    '</tr>';
            $("#contract_modal_results").append(result);
        });
    }

    add_contract_modal([contract]);

    if ($("body#catalog_detail").length > 0 && contract ){
      $("h1.title").after('<a href="#" id="title_contracts">Show contract (Example, display test)</a>');
    }
    $("body").on('click','#title_contracts',function(){console.log('click');$("#contract_modal").modal({show:true});});

    |;
}

sub api_routes {
    my ( $self, $args ) = @_;

    my $contracts_spec_str = $self->mbf_read('openapi.json');
    my $permissions_spec_str = $self->mbf_read('permissions.json');
    my $spec     = { %{decode_json($contracts_spec_str)}, %{decode_json($permissions_spec_str)} };

    return $spec;
}

sub api_namespace {
    my ($self) = @_;

    return 'contracts';
}

1;
