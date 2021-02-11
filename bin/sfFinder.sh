#!/bin/bash
#
#              INGLÊS/ENGLISH
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  http://www.gnu.org/copyleft/gpl.html
#
#
#             PORTUGUÊS/PORTUGUESE
#  Este programa é distribuído na expectativa de ser útil aos seus
#  usuários, porém NÃO TEM NENHUMA GARANTIA, EXPLÍCITAS OU IMPLÍCITAS,
#  COMERCIAIS OU DE ATENDIMENTO A UMA DETERMINADA FINALIDADE.  Consulte
#  a Licença Pública Geral GNU para maiores detalhes.
#  http://www.gnu.org/copyleft/gpl.html
#
#  Copyright (C) 2019  Universidade Estadual Paulista "Júlio de Mesquita Filho"
#
#  Universidade Estadual Paulista "Júlio de Mesquita Filho" (UNESP)
#  Faculdade de Ciências Agrárias e Veterinárias (FCAV)
#  Laboratório de Bioinformática (LB)
#
#  Daniel Guariz Pinheiro
#  dgpinheiro@gmail.com
#  http://www.fcav.unesp.br 
#

# Please set SFFINDER_HOME

SFFINDER_HOME="/data/GitHub/sfFinder"
NUM_THREADS=2
# The index must be created from fasta sequences only with ID (UniRef IDs)
UNIREF_FASTA="/data/databases/uniref/uniref100_sample.fa"
# The UniRef IDs and their descriptions must be in a TAB-separated TXT file
UNIREF_DESCRIPTION="/data/databases/uniref/uniref100_sample.txt"
# The diamond index
UNIREF_DIAMOND_INDEX="/data/databases/uniref/uniref100_sample.dmnd"
# The BLAST index
UNIREF_BLAST_INDEX="/data/databases/uniref/uniref100_sample"
# TMP_4_TCOFFEE
export TMP_4_TCOFFEE="/data/tmp"
# Specifies the number of random sequences for calibration step
NUM_RANDOM_SEQS=100000

CURRDIR=`pwd`

if [ ! ${SFFINDER_HOME} ]; then
	echo "[ERROR] Please set SFFINDER_HOME within $0 script" 1>&2
	exit
fi

if [ ! -e "${UNIREF_FASTA}" ]; then
	echo "[ERROR] Wrong UniRef FASTA file (${UNIREF_FASTA})" 1>&2
	exit
fi

if [ ! -e "${UNIREF_DESCRIPTION}" ]; then
	echo "[ERROR] Wrong UniRef DESCRIPTION text file (${UNIREF_DESCRIPTION})" 1>&2
	exit
fi

if [ ! -e "${UNIREF_DIAMOND_INDEX}" ]; then

	echo "[WARN] UniRef FASTA file (${UNIREF_FASTA}) must be indexed by DIAMOND" 1>&2

	echo "Making DIAMOND index for ${UNIREF_FASTA} ..."

	diamond makedb	--in ${UNIREF_FASTA} \
			--db ${UNIREF_DIAMOND_INDEX} \
			1> ${UNIREF_DIAMOND_INDEX}.makedb.out.txt \
			2> ${UNIREF_DIAMOND_INDEX}.makedb.err.txt
fi

i=0; while read line; do blastidxfiles[ $i ]=$line; ((i++)); done < <(ls ${UNIREF_BLAST_INDEX}*pin 2>/dev/null); 

if [ "${#blastidxfiles[@]}" -eq "0" ]; then
	echo "${#blastidxfiles[@]}"

	echo "[WARN] UniRef FASTA file (${UNIREF_FASTA}) must be indexed by BLAST" 1>&2

	echo "Making BLAST index for ${UNIREF_FASTA} ..."

	makeblastdb	-dbtype prot \
			-parse_seqids \
			-in ${UNIREF_FASTA} \
			-out ${UNIREF_BLAST_INDEX} \
			1> ${UNIREF_BLAST_INDEX}.makeblastdb.log.out.txt \
			2> ${UNIREF_BLAST_INDEX}.makeblastdb.log.err.txt

fi

inprotfamname=$1

if [ ! ${inprotfamname} ]; then
	echo "[ERROR] Missing input protein family name" 1>&2
	exit	
fi

inprotfamfasta=$2

if [ ! ${inprotfamfasta} ]; then
	echo "[ERROR] Missing input protein family fasta file" 1>&2
	exit
else
	if [ ! -e ${inprotfamfasta} ]; then
		echo "[ERROR] Wrong file (${inprotfamfasta})" 1>&2
		exit
	fi	
fi

outdir=$3

if [ ! ${outdir} ]; then
	echo "[ERROR] Missing output directory" 1>&2
	exit
else
	if [ ! -d ${outdir} ]; then
		echo "[ERROR] Wrong directory (${outdir})" 1>&2
		exit
	fi	
fi

declare -i nmatches=0

if [ ! -e "${outdir}/uniref/${inprotfamname}_x_uniref.tsv" ]; then

	echo "Getting UniRef correspondences with DIAMOND aligner ..."

	mkdir -p  ${outdir}/uniref

	diamond blastp	--threads ${NUM_THREADS} \
			--db ${UNIREF_DIAMOND_INDEX} \
			--out ${outdir}/uniref/${inprotfamname}_x_uniref.tsv \
			--outfmt 6 \
			--query ${inprotfamfasta} \
			--query-cover 99 \
			--subject-cover 99 \
			--top 1 \
			--evalue 1e-5 \
			--more-sensitive \
			1> ${outdir}/uniref/${inprotfamname}_x_uniref.log.out.txt \
			2> ${outdir}/uniref/${inprotfamname}_x_uniref.log.err.txt

	echo "Getting the UniRef best maches from the alignment results ..."

	cat ${outdir}/uniref/${inprotfamname}_x_uniref.tsv | cut -f 1,2 | sort | uniq > ${outdir}/uniref/${inprotfamname}_x_uniref.MATCHES.txt
	nmatches=`cat ${outdir}/uniref/${inprotfamname}_x_uniref.MATCHES.txt | wc -l`
	cut -f 2 ${outdir}/uniref/${inprotfamname}_x_uniref.MATCHES.txt | sort | uniq > ${outdir}/uniref/${inprotfamname}_x_uniref.UNIREF.txt

fi
	
if [ "${nmatches}" -eq "0" ]; then
	echo "[ERROR] No DIAMOND matches found with UniRef" 1>&2
	exit
fi

if [ ! -e "${outdir}/uniref/${inprotfamname}.fa" ]; then
	echo "Getting UniRef fasta sequences from UniRef ..."

	pullseq	-n ${outdir}/uniref/${inprotfamname}_x_uniref.UNIREF.txt \
		-i ${UNIREF_FASTA} \
		1> ${outdir}/uniref/${inprotfamname}.fa \
		2> ${outdir}/uniref/${inprotfamname}.log.err.txt

fi

if [ ! -e "${outdir}/tcoffee/${inprotfamname}.aln" ]; then
	
	echo "Running T-COFFEE for Multiple Sequence Alignment of ${inprotfamname} ..."
	
	mkdir -p ${outdir}/tcoffee
	
	t_coffee	${outdir}/uniref/${inprotfamname}.fa \
			-mode mcoffee \
			-n_core ${NUM_THREADS} \
			-output fasta_aln \
			-newtree ${outdir}/tcoffee/${inprotfamname}.dnd \
			-outfile ${outdir}/tcoffee/${inprotfamname}.aln \
			1> ${outdir}/tcoffee/${inprotfamname}.tcoffee.out.txt \
			2> ${outdir}/tcoffee/${inprotfamname}.tcoffee.err.txt
	
	if [ ! -e "${outdir}/tcoffee/${inprotfamname}.aln" ]; then
		echo "[ERROR] TCoffee doesn't generate the alignment for protein family (${inprotfamname}) " 1>&2
		exit
	fi
	
fi

if [ ! -e "${outdir}/flowerpower/fp-workspace/final/final.fa" ]; then

	echo "Running FlowerPower for ${inprotfamname} ..."

	mkdir -p ${outdir}/flowerpower

	abs_path_aln=$(readlink -f ${outdir}/tcoffee/${inprotfamname}.aln)

	cd ${outdir}/flowerpower

	flowerpower.pl	--fphits 2000 \
			--psievalue 1 \
			-a ${abs_path_aln} \
			-d ${UNIREF_BLAST_INDEX} \
			--tempcheck 1 \
			-t ${NUM_THREADS} \
			1> ./flowerpower.log.out.txt \
			2> ./flowerpower.log.err.txt

	cd ${CURRDIR}

fi

mkdir -p ${outdir}/hmms

shopt -s nullglob

for modfile in ${outdir}/flowerpower/fp-workspace/final/last.*.mod; do 
	hmmfilename=`basename ${modfile} | sed "s/last/${inprotfamname}/"`
	if [ ! -e "${outdir}/hmms/${hmmfilename}" ]; then
		if [ -e ${modfile} ]; then
			ln -s $(readlink -f ${modfile}) ${outdir}/hmms/${hmmfilename}
		fi			
	fi		
done

if [ ! -e "${outdir}/flowerpower/fp-workspace/final/last.subfam" ]; then
	echo "[ERROR] FlowerPower had some problem and did'nt generate the last.subfam file" 1>&2
	exit
fi

mkdir -p ${outdir}/fa

rm -f ${outdir}/fa/*.txt
subfam=""
subfamregex='^%subfamily[[:space:]]+(N[0-9]+)'
seqidregex='^>([^[:space:]]+)'
while read line; do
	if [[ ${line} =~ ${subfamregex} ]]; then
		subfam=${BASH_REMATCH[1]}
	elif [[ ${line} =~ ${seqidregex} ]]; then
		seqid=${BASH_REMATCH[1]}
		#echo -e "${seqid}\t${inprotfamname}\t${inprotfamname}.${subfam}" 
		echo ${seqid} >> ${outdir}/fa/${inprotfamname}.${subfam}.txt
	fi		
done < ${outdir}/flowerpower/fp-workspace/final/last.subfam

for seqtxt in ${outdir}/fa/*.txt; do 
	seqfafilename=`basename ${seqtxt} .txt`
	seqfa=${outdir}/fa/${seqfafilename}.fa
	if [ ! -e "${seqfa}" ]; then
		pullseq -n ${seqtxt} \
			-i ${outdir}/flowerpower/fp-workspace/final/universe.fa \
			| sed 's/^\(>.*\)$/\1\t'${inprotfamname}'\t'${seqfafilename}'/' \
			1> ${seqfa} \
			2> /dev/null
	fi		
done

# Perform model calibration in hmmscore with random sequences
mkdir -p ${outdir}/hmms/parameters

rm -f ${outdir}/hmms/run_hmmscore_calibrate.sh

for modfile in ${outdir}/hmms/${inprotfamname}.*.mod; do 
	hmmbasename=`basename ${modfile} .mod`
	if [ ! -e "${outdir}/hmms/parameters/${hmmbasename}.mlib" ]; then
		echo "hmmscore	${outdir}/hmms/parameters/${hmmbasename} -i ${modfile} -sw 0 -calibrate ${NUM_RANDOM_SEQS} 1> ${outdir}/hmms/parameters/${hmmbasename}.log.out.txt 2> ${outdir}/hmms/parameters/${hmmbasename}.log.err.txt" >> ${outdir}/hmms/run_hmmscore_calibrate.sh
	fi		
done

if [ -e "${outdir}/hmms/run_hmmscore_calibrate.sh" ]; then
	echo "HMM Calibration step ..."

	parallel --gnu -j ${NUM_THREADS} < ${outdir}/hmms/run_hmmscore_calibrate.sh &>> ${outdir}/hmms/run_hmmscore_calibrate.log.all.txt 

fi

for mlibfile in ${outdir}/hmms/parameters/${inprotfamname}.*.mlib; do
	bn=`basename ${mlibfile} .mlib`
	modfile="${bn}.mod"
        cp ${mlibfile} ${mlibfile}.backup
	cat ${mlibfile}.backup | \
		sed 's/^MODLIBMOD \(\S\+\) \(.\+\) model number /MODLIBMOD \1 \.\/hmms\/\1 model number /' | \
		sed "s/^% Inserted Files:\(\s\+\).\+/% Inserted Files:\1\.\/hmms\/${modfile}/" | \
		sed "s/^insert\(\s\+\).\+/insert\1\.\/hmms\/${modfile}/" \
		> ${mlibfile}
done
