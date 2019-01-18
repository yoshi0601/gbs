#!/usr/bin/perl
use strict;
use warnings;

# filterVariantPattern.pl
# less XXXXX.vcf | perl fileterVariantPattern.pl 1 0 0 

# 



while(<STDIN>) {    
    print if (/^#/);
    my @data = split(/\t/);  
    my $sampleNum = scalar(@data) - 9;
    if ($sampleNum > 0) {
        my $presentBit = "";
        for(my $i=0; $i<$sampleNum; $i++) {
            my $pos = $i + 9;
            $presentBit = $presentBit . &extGeno($data[$pos]);
        };

    next if $presentBit =~ /-/;
    my $givenBit = join("",@ARGV);  
    # output
    print if ($givenBit eq $presentBit);
    }
}

# Subroutine to convert 0/0 and 1/1 to 0 and 1
sub extGeno {
    my ($data) = @_;
    my @data = split(/:/,$data);
    my $geno;
    if ($data[0] eq "0/0") {
        $geno = 0;
    } elsif ($data[0] eq "1/1") {
        $geno = 1;
    } else {
        $geno = -1;
    }
   return $geno;
}