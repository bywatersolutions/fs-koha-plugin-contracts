package Koha::Contract;

# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

use Modern::Perl;

use Carp;

use Koha::Database;

use base qw(Koha::Object);

use Koha::Acquisition::Bookseller;

=head1 NAME
Koha::Contract - Koha Contract Object class
=head1 API
=head2 Class methods

=head3 copyright_holder
Return the vendor linked to this contract
=cut

sub copyright_holder {
    my ( $self ) = @_;
    my $rs = $self->_result->copyright_holder;
    return unless $rs;
    return Koha::Acquisition::Bookseller->_new_from_dbic( $rs );
}

=head3 permissions

Return the permissions linked to this contract

=cut

sub permissions {
    my ( $self ) = @_;
    my $rs = $self->_result->koha_plugin_com_bywatersolutions_contracts_permissions;
    return unless $rs;
    return Koha::ContractPermissions->_new_from_dbic( $rs );
}

=head2 Internal methods
=head3 _type
=cut

sub _type {
    return 'KohaPluginComBywatersolutionsContractsContract';
}

1;
