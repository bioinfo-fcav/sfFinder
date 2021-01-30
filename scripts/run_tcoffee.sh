#!/bin/bash

indir=$1
outdir=$2

mkdir -p ${outdir}

#filelist="$indir/RHDO.fa  $indir/RHMO.fa  $indir/TDLH.fa"

export TMP_4_TCOFFEE="/data/tmp"

#for seq in `ls ${indir}/*.fa`; do
for seq in $filelist; do

                bn=`basename ${seq} .fa`
                echo "Running T_COFFEE for ${seq}"

		t_coffee ${seq} -mode mcoffee -output fasta_aln -outfile ${outdir}/${bn}.aln

done

