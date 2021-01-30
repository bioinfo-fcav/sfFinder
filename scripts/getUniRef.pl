#!/usr/bin/env perl

use strict;
use warnings;

my $infile = $ARGV[0];
die "Missing input file" unless ($infile);
my $outdir = $ARGV[1];
die "Missing output directory" unless ($outdir);

my $unireffile = $ARGV[2];
die "Missing uniref fasta file" unless ($unireffile);

my %data;

open(IN, "<", $infile) or die $!;

while(<IN>) {
	chomp;
	if ($_=~/^family\tuniref\tacc/) {
		next;
	} else {
		my ($family, $uniref, $acc) = split(/\t/ , $_);
		
		$data{$family}->{$uniref} = undef;
	}
}

close(IN);

foreach my $family (keys %data) {
	print $family,"\n";
	my $r = int(rand(100));
	my $tmpname = '/tmp/tmp_'.$r.'_family_'."$family.txt";

	open(TMP, ">", $tmpname) or die $!;
	foreach my $unirefid (keys %{ $data{$family} })  {
		print TMP $unirefid,"\n";
	}
	close(TMP);
	
	`pullseq -i $unireffile -n $tmpname > $outdir/$family.fa`;
	
	unlink($tmpname);
}

