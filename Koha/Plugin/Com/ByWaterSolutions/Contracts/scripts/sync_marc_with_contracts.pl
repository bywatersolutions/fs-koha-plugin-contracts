#!/usr/bin/perl
use Modern::Perl;
use Getopt::Long;
use Koha::Script;
use Koha::Plugin::Com::ByWaterSolutions::Contracts;
use Koha::Contracts;
use Try::Tiny;

my $confirm;

my $result = GetOptions(
    'confirm'   => \$confirm,
);

unless ($result) {
    print_usage();
    die "Invalid options";
}

unless ( $confirm ) { 
    print_usage();
    exit 0;
}

sub print_usage {
    print <<_USAGE_;
Sync contracts with MARC 542 fields

Valid options:
  --confirm      Without confirm nothing happens 

Examples:
  sync_contracts.pl --confirm
_USAGE_
}

if ( $confirm ) {
    print "Find all contracts and sync the resourses's 542 data \n";
    
    my $contracts = Koha::Contracts->search();
    my $total = $contracts->count;
    my $processed = 0;
    
    print "Found $total contracts to sync.\n\n";
    
    #loop through each contract
    while (my $contract = $contracts->next) {
        my $id = $contract->contract_id;
        my $number = $contract->contract_number;
        
        print "Processing contract $id ($number)...\n";
        
        try {
            Koha::Plugin::Com::ByWaterSolutions::Contracts->new()->sync_all_resources_for_contract({ contract_id => $id });
            $processed++;

            print "  Synced successfully for $id ($number)\n";
        }
        catch {
            warn "  ERROR syncing contract $id ($number): $_\n";
        }
    }

    print "Sync complete: $processed / $total contracts\n";
}
