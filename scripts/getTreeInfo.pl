#!/usr/bin/env perl

use strict;
use warnings;

use Storable;

my $infile=$ARGV[0];

die "Missing input file (.tree)" unless ($infile);
die "Wrong input file ($infile)" unless (-e $infile);

my $annfile=$ARGV[1];

die "Missing annotation file (.txt)" unless ($annfile);
die "Wrong input file ($annfile)" unless (-e $annfile);

my $hr_annot;

if (-e "$annfile.dump") {
	$hr_annot = retrieve("$annfile.dump");
} else {
	open(ANN, "<", $annfile) or die $!;

	while(my $l = <ANN>) {
		chomp($l);
		my ($id, $desc)=split(/\t/, $l);
		$desc=~s/\sn=\d+ .*$//;
		#print $id,"\t",$desc,"\n";
		$hr_annot->{$id} = $desc;
	}
	close(ANN);

	store $hr_annot, "$annfile.dump";
}

my $outfile=$ARGV[2];
die "Missing output file (text file with annotation)" unless ($outfile);


open(IN, "<", $infile) or die $!;
open(OUT, ">", $outfile) or die $!;

while(my $l = <IN>) {
	while($l=~/\b([A-Z][A-Za-z_\.0-9]+)\b/g) {
		my $id = $1;
		print OUT $id,"\t",$hr_annot->{$id},"\n";
	}
}

close(IN);
close(OUT);
