package Koha::ContractPermission;

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
use Koha::Contracts;

use base qw(Koha::Object);


=head1 NAME
Koha::ContractPermission - Koha Contract Permission Object class
=head1 API
=head2 Class methods

=head3 contract

Return the contract linked to this permission

=cut

sub contract {
    my ( $self ) = @_;
    my $rs = $self->_result->contract;
    return unless $rs;
    return Koha::Contract->_new_from_dbic( $rs );
}

=head3 resources

Return the contract resources linked to this permission

=cut

sub resources {
    my ( $self ) = @_;
    my $rs = $self->_result->resources;
    return unless $rs;
    return Koha::ContractResources->_new_from_dbic( $rs );
}

=head2 Internal methods
=head3 _type
=cut

sub _type {
    return 'KohaPluginComBywatersolutionsContractsPermission';
}

1;
