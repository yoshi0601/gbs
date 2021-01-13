#!/usr/bin/perl

while (<STDIN>) {
        chomp;

        if (/^>/) {

                $i++;
                close FILE unless ($i == 1);
                open(FILE,">$_") or die "$i:$!\n";

        }
        print FILE "$_\n";
}

close FILE;
