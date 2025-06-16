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

    my @components = ();
    
    # Get child components using get_marc_components
    my $max_results = C4::Context->preference('MaxComponentRecords') || 10;
    my $child_components = $biblio->get_marc_components($max_results);
    
    # Process child relationships
    if ($child_components && @{$child_components}) {
        for my $component (@{$child_components}) {
            # Convert the raw record to a MARC record
            my $record = C4::Search::new_record_from_zebra('biblioserver', $component);
            
            # Extract the biblionumber
            my $child_id = Koha::SearchEngine::Search::extract_biblionumber($record);
            
            # Get the full biblio record
            my $child_biblio = Koha::Biblios->find($child_id);
            my $child_title = '';
            my $child_subtitle = '';
            
            if ($child_biblio) {
                $child_title = $child_biblio->title || '';
                $child_subtitle = $child_biblio->subtitle || '';
                if (!$child_title) {
                    my $biblio_data = C4::Biblio::GetBiblioData($child_id);
                    $child_title = $biblio_data->{title} if $biblio_data;
                }
            }
            
            push @components, {
                relationship_type => 'child',
                related_title => $child_title || '',
                related_id => $child_id || '',
                related_subtitle => $child_subtitle || '',
            };
        }
    }
    
    # Get host relationships by examining the 773 fields
    my $marc_record = $biblio->metadata->record;
    my $host_id;
    if ($marc_record) {
        foreach my $field ($marc_record->field('773')) {
            $host_id = $field->subfield('w') || '';

            my $host_biblio = Koha::Biblios->find($host_id);
            my $host_title = '';
            my $host_subtitle = '';

            if ($host_biblio) {
                $host_title = $host_biblio->title || '';
                $host_subtitle = $host_biblio->subtitle || '';
            }

            push @components, {
                relationship_type => 'host',
                related_title => $host_title || '',
                related_id => $host_id || '',
                related_subtitle => $host_sutitle || '',
            };
        }


    }

    return $c->render( status => 200, openapi => \@components );
}

1;
