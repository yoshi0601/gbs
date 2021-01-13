#!/usr/bin/perl

use strict;
use warnings;

if (scalar(@ARGV) < 3) {
        die "## usage \nperl this.pl startpos endpos comment\n\n";
}

my ($start,$end, $myanno) = @ARGV;

if ($start > $end) {
        my $a = $end;
        $end = $start;
        $end = $a;
}
 
my $size = $end - $start + 1;

my $anno;
my $seq;
while(<STDIN>) {
        chomp;
        if (/^>/) {
                $anno = $_;
                next;
        }
        $seq .= $_;
}

# extract user-defined region.
my $newseq = substr($seq, $start-1, $size);

# display
$newseq =~ s/.{80}/$&\n/g;
print ">$myanno|$start-$end\n";
print "$newseq\n\n";
