package Koha::Plugin::Com::ByWaterSolutions::Contracts::BiblioController;

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

use CGI;
use Try::Tiny;

use Koha::Biblios;

=head1 Koha::Plugin::Com::ByWaterSolutions::Contracts::BiblioController
A class implementing the controller code for Biblios
=head2 Class methods

=head3 list

Controller function that handles listing Koha::Biblio objects

=cut

sub list_biblios {
    my $c = shift->openapi->valid_input or return;
    return try {
        my $resources_set = Koha::Biblios->search({});
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

sub get_components_for_biblio {
    my $c = shift->openapi->valid_input or return;
    
    my $biblionumber = $c->validation->param('biblionumber');
    return $c->render( status => 404, openapi => { error => "Biblionumber not found" } )
        unless $biblionumber;
    
    my $biblio = Koha::Biblios->find($biblionumber);
    return $c->render( status => 404, openapi => { error => "Biblio not found" } )
        unless $biblio;
    
    # Custom component extraction instead of using get_marc_components()
    my $marc_record = $biblio->metadata->record;
    my @components = ();
    
    if ($marc_record) {
        # Extract component information from relevant MARC fields
        # 773 fields - this record is a component part of another record
        foreach my $field ($marc_record->field('773')) {
            push @components, {
                relationship_type => 'host',
                host_title => $field->subfield('t') || '',
                host_id => $field->subfield('w') || '',
            };
        }
        
    }
    
    return $c->render( status => 200, openapi => \@components );
}

1;
