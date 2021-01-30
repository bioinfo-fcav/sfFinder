#!/usr/bin/env perl
  
use strict;
use warnings;

use File::Basename;

# comando: ./get_hmm_models.pl . OUT 

my $dir=$ARGV[0];
my $outdir=$ARGV[1];
$outdir||=".";

my $outname=$ARGV[2];
$outname||="ALL";

opendir( DIR, $dir ) or die $!;

while ( my $d = readdir(DIR) ) {

    my @files  = glob("$d/*.mod");
    my $family = basename($d);
    foreach my $f (@files) {
        my $subfam = basename($f, '.mod' );
        my $cmd1 = "/usr/local/bioinfo/sam/bin/hmmscore $outdir/$family.$subfam -i $f -sw 0 -calibrate 100000";
        `$cmd1`;
        my $cmd2 = "cat $outdir/$family.$subfam.mlib | sed 's/^MODLIBMOD ".'\S\+'."/MODLIBMOD $family.$subfam/' >> ./$outname.mlib";
        `$cmd2`;
    }
}



