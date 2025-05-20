package Koha::Plugin::Com::ByWaterSolutions::Contracts;

use Modern::Perl;

use C4::Installer qw(TableExists);
use C4::Context qw(userenv);
use Koha::Patrons;

use JSON qw(decode_json);
use List::MoreUtils qw( any );

use base qw(Koha::Plugins::Base);

## Here we set our plugin version
our $VERSION         = "{VERSION}";
our $MINIMUM_VERSION = "22.11.00";

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
    require Koha::ContractResources;


    # register the additional schema classes
    Koha::Schema->register_class(KohaPluginComBywatersolutionsContractsContract => 'Koha::Schema::Result::KohaPluginComBywatersolutionsContractsContract');
    Koha::Schema->register_class(KohaPluginComBywatersolutionsContractsPermission => 'Koha::Schema::Result::KohaPluginComBywatersolutionsContractsPermission');
    Koha::Schema->register_class(KohaPluginComBywatersolutionsContractsResource => 'Koha::Schema::Result::KohaPluginComBywatersolutionsContractsResource');
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
    my $dbh = C4::Context->dbh;

    my $contracts_table = $self->get_qualified_table_name('contracts');
    unless( TableExists( $contracts_table ) ){
        $dbh->do( "
            CREATE TABLE `$contracts_table` (
                contract_id INT(10) NOT NULL AUTO_INCREMENT,
                supplier_id INT(10) NULL,
                contract_number VARCHAR(255),
                created_on timestamp NOT NULL DEFAULT current_timestamp(),
                created_user INT(11) NOT NULL,
                updated_on timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
                updated_user INT(11) NOT NULL,
                rvn VARCHAR(255),
                PRIMARY KEY (`contract_id`),
                CONSTRAINT `contracts_plugin_contracts_ibfk_1` FOREIGN KEY (`supplier_id`) REFERENCES `aqbooksellers` (`id`)
            ) ENGINE = INNODB;
        " );
    }
    my $permissions_table = $self->get_qualified_table_name('permissions');
    unless( TableExists( $permissions_table ) ){
        $dbh->do( "
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
        $dbh->do( "
            CREATE TABLE $resources_table (
                resource_id INT(10) NOT NULL AUTO_INCREMENT,
                permission_id INT( 10 ) NULL,
                biblionumber INT(10) NOT NULL,
                PRIMARY KEY (`resource_id`),
                CONSTRAINT `contracts_plugin_resources_ibfk_1` FOREIGN KEY (`permission_id`) REFERENCES `$permissions_table` (`permission_id`)
            ) ENGINE = INNODB;
        " );

    }

    $dbh->do("INSERT IGNORE INTO authorised_value_categories( category_name, is_system ) VALUES ('PERMISSION_TYPES', NULL)");
    $dbh->do("INSERT IGNORE INTO authorised_values( category, lib, authorised_value ) VALUES ('PERMISSION_TYPES','Public Domain, No Notice','A1 B1a C1 D1 E1 F1 G1 H1 I1 J1 K1')");
    $dbh->do("INSERT IGNORE INTO authorised_values( category, lib, authorised_value ) VALUES ('PERMISSION_TYPES','Permission Granted','A1 B1a C1 D2 E1 F1 G2 H2 I1 J1 K3')");
    $dbh->do("INSERT IGNORE INTO authorised_values( category, lib, authorised_value ) VALUES ('PERMISSION_TYPES','Permission Denied','A1 B8a C1 D2 E1 F2a F2b G2 H2 I1 J9 P1 P4 P13 P15')");
    $dbh->do("INSERT IGNORE INTO authorised_values( category, lib, authorised_value ) VALUES ('PERMISSION_TYPES','Contract Conditions','A1 B4b C1 D2 E1 F9 G1 H2 I1 J1 K2j')");
    $dbh->do("INSERT IGNORE INTO authorised_values( category, lib, authorised_value ) VALUES ('PERMISSION_TYPES','Protected','A1 B4b C1 D2 E1 F9 G2 H2 I1 J1 K2j')");
    $dbh->do("INSERT IGNORE INTO authorised_values( category, lib, authorised_value ) VALUES ('PERMISSION_TYPES','Public Domain','A1 B1a C1 D1 E1 F1 G1 H1 I1 J1 K1')");
    $dbh->do("INSERT IGNORE INTO authorised_values( category, lib, authorised_value ) VALUES ('PERMISSION_TYPES','Limited Permission Granted','A1 B1a C1 D2 E1 F1 G2 H2 I1 J1 K3a M3a N4a')");

    return 1;
}

sub configure {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $userenv = C4::Context->userenv;
    my $logged_in_user = Koha::Patrons->find( $userenv->{number} );
    my $template = $self->get_template({ file => 'config.tt' });
    if( $logged_in_user->is_superlibrarian ){
        if( $cgi->param('save') ){
            my $auth_users = $cgi->param('authorized_users');
            $self->store_data({
                authorized_users => $auth_users
            });
            $self->go_home();
        }
        else {
            my $auth_users = $self->retrieve_data('authorized_users');
            $template->param( authorized_users => $auth_users );
        }
    } else {
            $template->param( not_authorized => 1 );
    }
    print $cgi->header();
    print $template->output();
}

sub tool {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    $self->tool_step_1();
}

sub tool_step_1 {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};
    my $userenv = C4::Context->userenv;

    my $biblionumber = $cgi->param('biblionumber');
    my $template = $self->get_template({ file => 'contracts.tt' });
    $template->param( can_manage_contracts => 1 ) if $self->is_user_authorized({ borrowernumber => $userenv->{number} });
    my $count = Koha::Contracts->search()->count;
    $template->param( contracts_count => $count );
    $template->param( biblionumber => $biblionumber ) if $biblionumber;
    print $cgi->header();
    print $template->output();
}

sub is_user_authorized {
    my ( $self, $params ) = @_;
    my $borrowernumber = $params->{borrowernumber};

    my $auth_users = $self->retrieve_data('authorized_users');

    return any { $_ eq $borrowernumber } split(',',$auth_users);
}



sub upgrade {
    my ( $self, $args ) = @_;

    my $dbh = C4::Context->dbh;
    my $contracts_table = $self->get_qualified_table_name('contracts');

    try {
        $dbh->do("ALTER TABLE $contracts_table ADD rvn VARCHAR(255) AFTER updated_user");
    } catch {
        warn "ERROR DURING UPGRADE: $_";
    }

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
                        <h1 class="modal-title">Contract Info</h1>
                        <button type="button" class="closebtn" data-bs-dismiss="modal" aria-label="Close">x</button>
                    </div>
                    <div class="modal-body">
                        <table id="contract_modal_results" class="table">
                        </table>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                    </div>
                </div>
            </div>
        </div>
    |;
}

sub intranet_js {
    my ( $self ) = @_;

    return q|
    <script src="/api/v1/contrib/contracts/static/js/vendor.js"></script>
    <script src="/api/v1/contrib/contracts/static/js/biblio_details.js"></script>
    |;
}

sub api_routes {
    my ( $self, $args ) = @_;

    my $contracts_spec_str = $self->mbf_read('openapi.json');
    my $permissions_spec_str = $self->mbf_read('permissions.json');
    my $resources_spec_str = $self->mbf_read('resources.json');
    my $biblios_spec_str = $self->mbf_read('biblios.json');
    my $spec     = { %{decode_json($contracts_spec_str)}, %{decode_json($permissions_spec_str)}, %{decode_json($resources_spec_str)},  %{decode_json($biblios_spec_str)} };

    return $spec;
}

sub static_routes {
    my ( $self, $args ) = @_;

    my $spec_str = $self->mbf_read('staticapi.json');
    my $spec     = decode_json($spec_str);

    return $spec;
}

sub api_namespace {
    my ($self) = @_;

    return 'contracts';
}

1;
