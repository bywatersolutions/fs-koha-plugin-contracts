package Koha::Contracts;

use Modern::Perl;

use Koha::Database;
use Koha::Contract;

use base qw(Koha::Objects);

=head1 NAME

Koha::Contracts - Koha Contracts Object set class

=head1 API

=head2 Internal methods

=head3 _type

=cut

sub _type {
        return 'KohaPluginComBywatersolutionsContractsContract';
}

=head3 object_class

=cut

sub object_class {
        return 'Koha::Contract';
}

1;
