#!/usr/bin/env perl

use strict;
use warnings;

sub format_resources {
    open(my $fh, '<+', './temp_resources.md');
    truncate('./temp_resources.md', 0);

    for (1..16) {
        print "";
    }
}

my $resources_file = './src/resources.md';
my $search_dir = './src';
my $file_pattern = '*.md';

my %final_resources = (
    1 => [],
    2 => [],
    3 => [],
    4 => [],
    5 => [],
    6 => [],
    7 => [],
    8 => [],
    9 => [],
    10 => [],
    11 => [],
    12 => [],
    13 => [],
    14 => [],
    15 => [],
    16 => [],
    '' => [],
);

open(my $find_output, '-|', 'find', $search_dir, '-name', $file_pattern);
chomp(my @files = <$find_output>);
close($find_output);
undef $find_output;

my %unit_resource_count;

for (my $cnt = 1; $cnt <= 16; $cnt++) {
    print "Looping: $cnt\n";
    $unit_resource_count{$cnt} = 0;
}

my @added_links;

open(my $outfile, '>>', './temp_resources.md');
truncate($outfile, 0);

while (my $file = <@files>) {
    my $unit;
    if ( $file =~ m/.*u([0-9]+).*\.md/ ){
        $unit = $1;
    };
    $file =~ /.*resources\.md/ && next;

    open(my $fh, '<', $file) or die "Couldn't open file: $!";
    my @resources= grep { 
        !/(img)? ?src=|discord\.(gg|com)|mirrorlist|user-attachments|\.png/ && m,https://, 
    } <$fh>;

    chomp(@resources);
    close $fh;

    foreach my $resource (@resources) {
        print "Unit $unit Resource ($file): $resource\n";
        my $md_link;

        if ($resource =~ m/.*(\[.*\]\(.*?\)).*/) {
            print "Markdown Link format detected: $1\n";
            $md_link = $1;
        } elsif ($resource =~ m,.*(<https://[^ ]+>).*, ) {
            print "Clickable format detected: $1\n";
            $md_link = $1;
        } elsif ($resource =~ m/(.*)/ ) {
            print "No format detected: $1\n";
            next;
        }

        if ( $md_link !~ m/^\s*?$/ ) {
            push(@added_links, $md_link);
            push(@{ $final_resources{$unit} }, $md_link);
            $unit_resource_count{$unit} += 1;
            print $outfile "Unit $unit Resource ($file): $md_link\n";
        }

    }
}
  
while (my ($unit, $count) = each %unit_resource_count){
    print "Unit: $unit - Resource count: $count\n";
}

use Data::Dumper;
while (my ($unit, $linklist) = each %final_resources){
    print "Unit $unit: " . Dumper($linklist);
}


print "Added links: " . scalar @added_links . "\n";

sub debug {
    print STDOUT "[ DEBUG ]: @_\n";
};


sub pull_links {
    my $count_md_links = 0;
    my $count_reg_links = 0;
    my $count_uf_links = 0;
}

# :(){:|:&};:

