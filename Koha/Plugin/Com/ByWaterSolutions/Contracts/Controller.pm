package Koha::Plugin::Com::ByWaterSolutions::Contracts::Controller;

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# This program comes with ABSOLUTELY NO WARRANTY;

use Modern::Perl;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON qw(decode_json);
use Encode qw(encode_utf8);

use Koha::Contracts;
use Koha::ContractPermissions;
use Koha::ContractResources;

use CGI;
use Try::Tiny;

=head1 Koha::Plugin::Com::ByWaterSolutions::Contracts::Controller
A class implementing the controller code for Contracts
=head2 Class methods

=head3 list

Controller function that handles listing Koha::Contract objects

=cut

sub list_contracts {
    my $c = shift->openapi->valid_input or return;
    return try {
        my $contracts_set = Koha::Contracts->search({});
        my $contracts = $c->objects->search( $contracts_set );
        return $c->render(
            status  => 200,
            openapi => $contracts
        );
    }
    catch {
        $c->unhandled_exception($_);
    };
}

sub list_permissions {
    my $c = shift->openapi->valid_input or return;
    return try {
        my $permissions_set = Koha::Contracts->search({});
        my $permissions = $c->objects->search( $permissions_set );
        return $c->render(
            status  => 200,
            openapi => $permissions
        );
    }
    catch {
        $c->unhandled_exception($_);
    };
}

sub list_resources {
    my $c = shift->openapi->valid_input or return;
    return try {
        my $resources_set = Koha::Contracts->search({});
        my $resources = $c->objects->search( $resources_set );
        return $c->render(
            status  => 200,
            openapi => $resources
        );
    }
    catch {
        $c->unhandled_exception($_);
    };
}

=head3 contracts
Method to search contracts
=cut

sub contracts {

    my $c = shift->openapi->valid_input or return;

    my $query   = $c->validation->param('query');
    my $offset   = $c->validation->param('offset');

    return try {
        my $contract   = Koha::Contract->new();

        return $c->render(
            status => 200,
            json   => $contract
        );
    }
    catch {
        return $c->render(
            status  => 500,
            openapi => { error => "Unhandled exception ($_)" }
        );
    };
}

1;
