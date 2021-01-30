#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename;

my $file=$ARGV[0];
my $outfile=$ARGV[1];
$outfile||="./output.fa";

unlink($outfile);

my ($outdir, $outbasename);
$outdir = dirname($outfile);
$outbasename = basename($outfile, '.fa','.fasta');


foreach my $f (glob("$outdir/$outbasename".'_*.fa*')) {
    print "Removing $f ...","\n";
    unlink($f);
}

open(IN,"<", $file) or die $!;

while(<IN>){
    chomp;
    my $line = $_;
    if ($line =~/^>([^_]+)_(.*)/) {
        my ($family) = $1;
        my ($rawid) = $2;
        my $acc;
        if ( $rawid=~/^gi\|/ ) {
            my @info = split(/\|/, $rawid); 
            $acc=$info[3]; 
        } elsif ( $rawid=~/^([A-Z]{2,3}_?[0-9]+)/) {
            $acc=$1;
        } else {
            die "Not found pattern: $rawid";
        }
        
        print ">>>$family\t$acc\n";

        my $cmd='esearch -db protein -query "'.$acc.'" | efetch -db protein -format fasta >> '.$outdir.'/'.$outbasename.'_'.$family.'.fa';
        if (system("$cmd") ) {
            #die "Error: Problem with command: $cmd";
            print STDERR $line;
        }

    } elsif ( $line=~/unpublished/) {
        next;
    } else {
        die "Not found pattern: $_";
    }        
}

close(IN);


