#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename;

my $dir=$ARGV[0];

my @file = glob("$dir/*.fa");
foreach my $f (@file) {
	my $bn = basename($f,'.fa');
    #$bn=~s/^out_//;

	open(IN, "<", $f) or die $!;
	while(<IN>) {
		chomp;
		if ($_=~/^>(\S+)/) {
			my $seqid = $1;
			print $bn,"\t",$seqid,"\n";
		}
	}
	close(IN);
}
