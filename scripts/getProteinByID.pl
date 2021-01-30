#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename;

my $file=$ARGV[0];
my $outdir=$ARGV[1];


if (! $file) {
        die "Missing input file";
}

#if (scalar(glob("$outdir/*.fa"))) {
#    die "Error: Found files into $outdir";
#}

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
            if ($info[2] eq 'pdb') {
                $info[4]=~s/ .*$//;
                $acc=$info[3].'_'.$info[4];
            } else {
                $acc=$info[3]; 
            }
        } elsif ( $rawid=~/^([A-Z]{2,3}_?[0-9]+)/) {
            $acc=$1;
        } else {
            die "Not found pattern: $rawid";
        }
        
        print ">>>$family\t$acc\n";

        my $cmd='esearch -db protein -query "'.$acc.'" | efetch -db protein -format fasta >> '.$outdir.'/'.$family.'.fa';
        if (system("$cmd") ) {
            die "Error: Problem with command: $cmd";
            print STDERR $line;
        }

    } elsif ( $line=~/unpublished/) {
        warn 'Found Unpublished sequence!';
        next;
    } else {
        die "Not found pattern: $_";
    }        
}

close(IN);


