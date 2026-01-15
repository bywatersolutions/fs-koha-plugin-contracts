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

use Koha::Plugin::Com::ByWaterSolutions::Contracts;

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

sub get_contract {
    my $c = shift->openapi->valid_input or return;

    my $contract_id = $c->validation->param('contract_id');

    return try {
        my $contract = Koha::Contracts->find({ contract_id => $contract_id });
        return $c->render(
            status  => 200,
            openapi => $contract
        );
    }
    catch {
        $c->unhandled_exception($_);
    };
}

sub add_contract {
    my $c = shift->openapi->valid_input or return;

    my $contract_number = $c->validation->param('body')->{'contract_number'};
    my $supplier_id = $c->validation->param('body')->{'supplier_id'};
    my $rvn = $c->validation->param('body')->{'rvn'};
    my $users = $c->validation->param('body')->{'users'};
    my $patron = $c->stash('koha.user');
    unless( _check_auth( $patron ) ){
        return $c->render(
            status => 403,
            openapi => { error => "You are not allowed" }
        );
    }

    return try {
        my $contract = Koha::Contract->new({
            contract_number => $contract_number,
            supplier_id => $supplier_id,
            rvn         => $rvn,
            users       => $users,
            created_user => $patron->id,
            updated_user => $patron->id
        });

        $contract->store;

        return $c->render(
            status  => 200,
            openapi => $contract
        );
    }
    catch {
        $c->unhandled_exception($_);
    };
}

sub update_contract {
    my $c = shift->openapi->valid_input or return;

    my $contract_id = $c->validation->param('contract_id');
    my $contract_number= $c->validation->param('body')->{'contract_number'};
    my $rvn= $c->validation->param('body')->{'rvn'};
    my $users= $c->validation->param('body')->{'users'};
    my $supplier_id = $c->validation->param('body')->{'supplier_id'};
    my $patron = $c->stash('koha.user');

    unless( _check_auth( $patron ) ){
        return $c->render(
            status => 403,
            openapi => { error => "You are not allowed" }
        );
    }

    return try {
        my $contract = Koha::Contracts->find({ contract_id => $contract_id });

        # retain old contract number before updaing 
        my $old_contract_number = $contract->contract_number;

        $contract->contract_number( $contract_number ) if $contract_number;
        $contract->supplier_id( $supplier_id ) if $supplier_id;
        $contract->rvn( $rvn ) if $rvn;
        $contract->users( $users ) if $users;
        $contract->updated_user( $patron->id );
        $contract->store;
        $contract->discard_changes;

        Koha::Plugin::Com::ByWaterSolutions::Contracts->new()->sync_all_resources_for_contract({
            contract_id => $contract_id,
            old_contract_number => $old_contract_number
        });

        return $c->render(
            status  => 200,
            openapi => $contract
        );
    }
    catch {
        $c->unhandled_exception($_);
    };
}

sub delete_contract {
    my $c = shift->openapi->valid_input or return;

    my $contract_id = $c->validation->param('contract_id');
    my $patron = $c->stash('koha.user');
    unless( _check_auth( $patron ) ){
        return $c->render(
            status => 403,
            openapi => { error => "You are not allowed" }
        );
    }

    return try {
        my $contract = Koha::Contracts->find({ contract_id => $contract_id });

        my $contract_number = $contract->contract_number;

        my $permissions = $contract->permissions;
        while ( my $permission = $permissions->next ){
            my $resources = $permission->resources;
            
            #when deleting a contract all 542 data should be deleted from connected resourses/bibs
            while ( my $resource = $resources->next ) {
                Koha::Plugin::Com::ByWaterSolutions::Contracts->new()->remove_marc_from_contract({
                    biblionumber => $resource->biblionumber,
                    contract_number => $contract_number
                });
            }

            $resources->delete;
            $permission->delete;
        }
        $contract->discard_changes;
        $contract->delete;

        return $c->render(
            status  => 204,
            openapi => $contract
        );
    }
    catch {
        $c->unhandled_exception($_);
    };
}

sub _check_auth {
    my $patron = shift;
    my $plugin = Koha::Plugin::Com::ByWaterSolutions::Contracts->new();
    return $plugin->is_user_authorized({ borrowernumber => $patron->id });
}

1;
