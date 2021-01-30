#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename;

my @file = glob("./out_*cleaned.fasta");
foreach my $f (@file) {
	my $bn = basename($f,'_cleaned.fasta');
	$bn=~s/^out_//;

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
