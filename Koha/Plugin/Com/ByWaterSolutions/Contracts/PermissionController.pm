package Koha::Plugin::Com::ByWaterSolutions::Contracts::PermissionController;

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

use Koha::ContractPermissions;

use CGI;
use Try::Tiny;

=head1 Koha::Plugin::Com::ByWaterSolutions::Contracts::PermissionController
A class implementing the controller code for Contracts
=head2 Class methods

=head3 list

Controller function that handles listing Koha::Contract objects

=cut

sub list_permissions {
    my $c = shift->openapi->valid_input or return;
    return try {
        my $permissions_set = Koha::ContractPermissions->search({});
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

sub get_permission {
    my $c = shift->openapi->valid_input or return;

    my $permission_id = $c->validation->param('permission_id');
    return try {
        my $permission = Koha::ContractPermissions->find({ permission_id => $permission_id });
        return $c->render(
            status  => 200,
            openapi => $permission
        );
    }
    catch {
        $c->unhandled_exception($_);
    };
}

sub delete_permission {
    my $c = shift->openapi->valid_input or return;

    my $permission_id = $c->validation->param('permission_id');
    my $patron = $c->stash('koha.user');
    unless( _check_auth( $patron ) ){
        warn "not auth";
        return $c->render(
            status => 403,
            openapi => { error => "You are not allowed" }
        );
    }

    return try {
        my $permission = Koha::ContractPermissions->find({ permission_id => $permission_id });

        $permission->delete;

        return $c->render(
            status  => 204,
            openapi => $permission
        );
    }
    catch {
        $c->unhandled_exception($_);
    };
}

sub update_permission {
    my $c = shift->openapi->valid_input or return;

    my $permission_id = $c->validation->param('permission_id');
    my $permission_type= $c->validation->param('body')->{'permission_type'};
    my $permission_code= $c->validation->param('body')->{'permission_code'};
    my $form_signed= $c->validation->param('body')->{'form_signed'};
    my $note= $c->validation->param('body')->{'note'};
    my $patron = $c->stash('koha.user');
    unless( _check_auth( $patron ) ){
        warn "not auth";
        return $c->render(
            status => 403,
            openapi => { error => "You are not allowed" }
        );
    }

    return try {
        my $permission = Koha::ContractPermissions->find({ permission_id => $permission_id });

        $permission->permission_type( $permission_type ) if $permission_type;
        $permission->permission_code( $permission_code ) if $permission_code;
        $permission->form_signed( $form_signed );
        $permission->note( $note );
        $permission->store;
        $permission->discard_changes;

        _update_contract( $permission, $patron );



        return $c->render(
            status  => 200,
            openapi => $permission
        );
    }
    catch {
        $c->unhandled_exception($_);
    };
}

sub add_permission {
    my $c = shift->openapi->valid_input or return;

    my $contract_id = $c->validation->param('body')->{'contract_id'};
    my $permission_type= $c->validation->param('body')->{'permission_type'};
    my $permission_code= $c->validation->param('body')->{'permission_code'};
    my $form_signed= $c->validation->param('body')->{'form_signed'};
    my $note= $c->validation->param('body')->{'note'};
    my $patron = $c->stash('koha.user');
    unless( _check_auth( $patron ) ){
        warn "not auth";
        return $c->render(
            status => 403,
            openapi => { error => "You are not allowed" }
        );
    }

    return try {
        my $permission = Koha::ContractPermission->new({
            contract_id => $contract_id,
            permission_type => $permission_type,
            permission_code => $permission_code,
            form_signed => $form_signed,
            note => $note
        });

        $permission->store;

        return $c->render(
            status  => 200,
            openapi => $permission
        );
    }
    catch {
        $c->unhandled_exception($_);
    };
}

sub _update_contract {
    my $permission = shift;
    my $patron = shift;
    my $contract = $permission->contract;
    $contract->updated_user( $patron->id );
    $contract->updated_on( undef );
    $contract->store();
}

sub _check_auth {
    my $patron = shift;
    my $plugin = Koha::Plugin::Com::ByWaterSolutions::Contracts->new();
    return $plugin->is_user_authorized({ borrowernumber => $patron->id });
}

1;
