use utf8;
package Koha::Schema::Result::KohaPluginComBywatersolutionsContractsPermission;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Koha::Schema::Result::KohaPluginComBywatersolutionsContractsPermission

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<koha_plugin_com_bywatersolutions_contracts_permissions>

=cut

__PACKAGE__->table("koha_plugin_com_bywatersolutions_contracts_permissions");

=head1 ACCESSORS

=head2 permission_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 contract_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 permission_type

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 permission_code

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 permission_date

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  default_value: 'current_timestamp()'
  is_nullable: 0

=head2 form_signed

  data_type: 'tinyint'
  is_nullable: 1

=head2 note

  data_type: 'longtext'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "permission_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "contract_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "permission_type",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "permission_code",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "permission_date",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    default_value => "current_timestamp()",
    is_nullable => 0,
  },
  "form_signed",
  { data_type => "tinyint", is_nullable => 1 },
  "note",
  { data_type => "longtext", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</permission_id>

=back

=cut

__PACKAGE__->set_primary_key("permission_id");

=head1 RELATIONS

=head2 contract

Type: belongs_to

Related object: L<Koha::Schema::Result::KohaPluginComBywatersolutionsContractsContract>

=cut

__PACKAGE__->belongs_to(
  "contract",
  "Koha::Schema::Result::KohaPluginComBywatersolutionsContractsContract",
  { contract_id => "contract_id" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

=head2 koha_plugin_com_bywatersolutions_contracts_resources

Type: has_many

Related object: L<Koha::Schema::Result::KohaPluginComBywatersolutionsContractsResource>

=cut

__PACKAGE__->has_many(
  "koha_plugin_com_bywatersolutions_contracts_resources",
  "Koha::Schema::Result::KohaPluginComBywatersolutionsContractsResource",
  { "foreign.permission_id" => "self.permission_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2022-06-30 13:38:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xhJ1QbRgKb1eSA9Q2M17SA
sub koha_object_class {
    'Koha::ContractPermission'
}

sub koha_objects_class {
    'Koha::ContractPermissions';
}

__PACKAGE__->has_many(
  "resources",
  "Koha::Schema::Result::KohaPluginComBywatersolutionsContractsResource",
  { "foreign.permission_id" => "self.permission_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
