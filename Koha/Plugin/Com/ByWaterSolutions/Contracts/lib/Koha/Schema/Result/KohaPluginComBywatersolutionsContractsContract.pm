use utf8;
package Koha::Schema::Result::KohaPluginComBywatersolutionsContractsContract;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Koha::Schema::Result::KohaPluginComBywatersolutionsContractsContract

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<koha_plugin_com_bywatersolutions_contracts_contracts>

=cut

__PACKAGE__->table("koha_plugin_com_bywatersolutions_contracts_contracts");

=head1 ACCESSORS

=head2 contract_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 supplier_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 contract_number

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 created_on

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 created_user

  data_type: 'integer'
  is_nullable: 0

=head2 updated_on

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 updated_user

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "contract_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "supplier_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "contract_number",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "created_on",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "created_user",
  { data_type => "integer", is_nullable => 0 },
  "updated_on",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "updated_user",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</contract_id>

=back

=cut

__PACKAGE__->set_primary_key("contract_id");

=head1 RELATIONS

=head2 koha_plugin_com_bywatersolutions_contracts_permissions

Type: has_many

Related object: L<Koha::Schema::Result::KohaPluginComBywatersolutionsContractsPermission>

=cut

__PACKAGE__->has_many(
  "koha_plugin_com_bywatersolutions_contracts_permissions",
  "Koha::Schema::Result::KohaPluginComBywatersolutionsContractsPermission",
  { "foreign.contract_id" => "self.contract_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 supplier

Type: belongs_to

Related object: L<Koha::Schema::Result::Aqbookseller>

=cut

__PACKAGE__->belongs_to(
  "supplier",
  "Koha::Schema::Result::Aqbookseller",
  { id => "supplier_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "RESTRICT",
  },
);



# Created by DBIx::Class::Schema::Loader v0.07049 @ 2022-06-30 13:38:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:GfUuKkvX7JmpbppuEEQ7vw
sub koha_object_class {
    'Koha::Contract'
}

sub koha_objects_class {
    'Koha::Contracts';
}

__PACKAGE__->has_many(
  "permissions",
  "Koha::Schema::Result::KohaPluginComBywatersolutionsContractsPermission",
  { "foreign.contract_id" => "self.contract_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->belongs_to(
  "copyright_holder",
  "Koha::Schema::Result::Aqbookseller",
  { "foreign.id" => "self.supplier_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "RESTRICT",
  },
);

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
