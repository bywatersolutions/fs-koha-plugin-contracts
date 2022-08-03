package Koha::Plugin::Com::ByWaterSolutions::Contracts::ResourceController;

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

=head1 Koha::Plugin::Com::ByWaterSolutions::Contracts::ResourceController
A class implementing the controller code for Contract Resources
=head2 Class methods

=head3 list

Controller function that handles listing Koha::ContractResource objects

=cut

sub list_resources {
    my $c = shift->openapi->valid_input or return;
    return try {
        my $resources_set = Koha::ContractResources->search({});
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

sub get_resource {
    my $c = shift->openapi->valid_input or return;

    my $resource_id = $c->validation->param('resource_id');
    return try {
        my $resource = Koha::ContractResources->find({ resource_id => $resource_id });
        return $c->render(
            status  => 200,
            openapi => $resource
        );
    }
    catch {
        $c->unhandled_exception($_);
    };
}

sub add_resource {
    my $c = shift->openapi->valid_input or return;

    my $permission_id = $c->validation->param('body')->{'permission_id'};
    my $biblionumber = $c->validation->param('body')->{'biblionumber'};
    my $patron = $c->stash('koha.user');
    return try {
        my $resource = Koha::Contract->new({
            permission_id => $permission_id,
            biblionumber => $biblionumber
        });

        $resource->store;

        return $c->render(
            status  => 200,
            openapi => $resource
        );
    }
    catch {
        $c->unhandled_exception($_);
    };
}

sub update_resource {
    my $c = shift->openapi->valid_input or return;

    my $resource_id = $c->validation->param('resource_id');
    my $permission_id = $c->validation->param('body')->{'permission_id'};
    my $biblionumber = $c->validation->param('body')->{'biblionumber'};
    my $patron = $c->stash('koha.user');
    return try {
        my $resource = Koha::Contracts->find({ resource_id => $resource_id });

        $resource->permission_id( $permission_id ) if $permission_id;
        $resource->biblionumber( $biblionumber ) if $biblionumber;
        $resource->store;
        $resource->discard_changes;


        return $c->render(
            status  => 200,
            openapi => $resource
        );
    }
    catch {
        $c->unhandled_exception($_);
    };
}

sub delete_resource {
    my $c = shift->openapi->valid_input or return;

    my $resource_id = $c->validation->param('resource_id');
    return try {
        my $resource = Koha::ContractResources->find({ resource_id => $resource_id });

        $resource->delete;

        return $c->render(
            status  => 204,
            openapi => $resource
        );
    }
    catch {
        $c->unhandled_exception($_);
    };
}

1;
