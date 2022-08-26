#! /usr/bin/perl
use MARC::Field;
use C4::Heading;
use C4::Context;
use C4::Biblio;

use Koha::Acquisition::Booksellers;
use Koha::Patrons;

use Getopt::Long;
use Text::CSV_XS;

my $file;
GetOptions(
    "f|file=s" => \$file
);

my $lines;
open($lines, '<', $file);
my $csv = Text::CSV_XS->new ({ binary => 1, sep_char => "\N{TAB}" });
my %links;
my $dbh = C4::Context->dbh;

my $resource_sth = $dbh->prepare('INSERT INTO koha_plugin_com_bywatersolutions_contracts_resources VALUES (?,?,?)');
my $permission_sth = $dbh->prepare('INSERT INTO koha_plugin_com_bywatersolutions_contracts_permissions VALUES (?,?,?,?,?,?,?)');
my $contract_sth = $dbh->prepare('INSERT INTO koha_plugin_com_bywatersolutions_contracts_contracts VALUES (?,?,?,?,?,?,?)');

my @cols = @{$csv->getline ($lines)};
$csv->column_names( @cols );

my %seen_p;
my %seen_c;
my %vendor;
my $last_c=0;

my $patron_id = Koha::Patrons->find({ userid => 'bwssupport' })->id;

while ( my $line = $csv->getline_hr($lines) ) {

$line->{'PERMISSION DATE'} ||= '1900-01-01';

unless( defined $vendor{ $line->{"SUPPLIER ID"} } ){
     my $bookseller = Koha::Acquisition::Booksellers->find({ accountnumber => $line->{"SUPPLIER ID"} });
     $vendor{ $line->{"SUPPLIER ID"} } = $bookseller ? $bookseller->id : undef; 
}


unless( $seen_c{ $line->{'CONTRACT NUMBER'} } ){
    $contract_sth->execute(
        undef,
        $vendor{ $line->{"SUPPLIER ID"} },
        $line->{'CONTRACT NUMBER'},
        undef,
        1,
        undef,
        1
    );
    $seen_c{ $line->{'CONTRACT NUMBER'} } = $dbh->last_insert_id();
}


$permission_sth->execute(
    $line->{'PERMISSION NUMBER'},
    $seen_c{ $line->{'CONTRACT NUMBER'} },
    $line->{'PERMISSION TYPE'},
    $line->{'PERMISSION CODE'},
    $line->{'PERMISSION DATE'},
    $line->{'FORM SIGNED'},
    $line->{'NOTE'}
) unless $seen_p{ $line->{'PERMISSION NUMBER'} };
$seen_p{ $line->{'PERMISSION NUMBER'} } = 1;


$resource_sth->execute(
    undef,
    $line->{'PERMISSION NUMBER'},
    $line->{'TITLENO'}
);


}


1;

