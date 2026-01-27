package Koha::ContractResource;

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
use Koha::ContractPermissions;

use base qw(Koha::Object);


=head1 NAME
Koha::ContractResource - Koha Contract Resource Object class
=head1 API
=head2 Class methods

=head3 permissions

Return the permission linked to this resource

=cut

sub permission {
    my ( $self ) = @_;
    my $rs = $self->_result->permission;
    return unless $rs;
    return Koha::ContractPermission->_new_from_dbic( $rs );
}

=head3 biblio

Return the biblio linked to this resource

=cut

sub biblio {
    my ( $self ) = @_;
    my $rs = $self->_result->biblio;
    return unless $rs;
    return Koha::Biblio->_new_from_dbic( $rs );
}

=head3 sync_to_marc

Syncs this resource's contract data to the biblio's MARC 542 field

=cut

sub sync_to_marc {
    my ($self) = @_;
    
    my $plugin = Koha::Plugin::Com::ByWaterSolutions::Contracts->new();
    return $plugin->add_marc_to_contract({ resource => $self });
}

=head3 remove_from_marc

Removes this resource's contract data from the biblio's MARC 542 field

=cut

sub remove_from_marc {
    my ($self) = @_;
    
    my $biblionumber = $self->biblionumber;
    my $contract_number = $self->permission->contract->contract_number;
    my $permission_code = $self->permission->permission_code;
    
    my $plugin = Koha::Plugin::Com::ByWaterSolutions::Contracts->new();
    return $plugin->remove_marc_from_contract({
        biblionumber => $biblionumber,
        contract_number => $contract_number,
        permission_code => $permission_code
    });
}

=head2 Internal methods

=head3 _type
=cut

sub _type {
    return 'KohaPluginComBywatersolutionsContractsResource';
}

1;
