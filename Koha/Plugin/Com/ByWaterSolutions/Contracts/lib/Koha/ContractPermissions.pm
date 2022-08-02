package Koha::ContractPermissions;

use Modern::Perl;

use Koha::Database;
use Koha::ContractPermission;

use base qw(Koha::Objects);

=head1 NAME

Koha::ContractPermissions - Koha Contract Permissions Object set class

=head1 API

=head2 Internal methods

=head3 _type

=cut

sub _type {
        return 'KohaPluginComBywatersolutionsContractsPermission';
}

=head3 object_class

=cut

sub object_class {
        return 'Koha::ContractPermission';
}

1;
