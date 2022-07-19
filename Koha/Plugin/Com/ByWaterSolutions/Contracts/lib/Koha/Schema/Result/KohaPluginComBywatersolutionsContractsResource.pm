use utf8;
package Koha::Schema::Result::KohaPluginComBywatersolutionsContractsResource;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Koha::Schema::Result::KohaPluginComBywatersolutionsContractsResource

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<koha_plugin_com_bywatersolutions_contracts_resources>

=cut

__PACKAGE__->table("koha_plugin_com_bywatersolutions_contracts_resources");

=head1 ACCESSORS

=head2 resource_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 permission_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 biblionumber

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "resource_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "permission_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "biblionumber",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</resource_id>

=back

=cut

__PACKAGE__->set_primary_key("resource_id");

=head1 RELATIONS

=head2 biblionumber

Type: belongs_to

Related object: L<Koha::Schema::Result::Biblio>

=cut

__PACKAGE__->belongs_to(
  "biblionumber",
  "Koha::Schema::Result::Biblio",
  { biblionumber => "biblionumber" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 permission

Type: belongs_to

Related object: L<Koha::Schema::Result::KohaPluginComBywatersolutionsContractsPermission>

=cut

__PACKAGE__->belongs_to(
  "permission",
  "Koha::Schema::Result::KohaPluginComBywatersolutionsContractsPermission",
  { permission_id => "permission_id" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2022-06-30 13:38:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MdCaDSXnSXA9onKN/4nuGg
sub koha_object_class {
    'Koha::ContractResource'
}

sub koha_objects_class {
    'Koha::ContractResources';
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
