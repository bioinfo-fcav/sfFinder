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

SFFINDER_HOME="/data/GitHub/sfFinder"
NUM_THREADS=2
# The UniRef IDs and their descriptions must be in a TAB-separated TXT file
UNIREF_DESCRIPTION="/data/databases/uniref/uniref100_sample.txt"

if [ ! ${SFFINDER_HOME} ]; then
	echo "[ERROR] Please set SFFINDER_HOME within $0 script" 1>&2
	exit
fi

if [ ! -e "${SFFINDER_HOME/bin/mkFProfiles.sh}" ]; then
	echo "[ERROR] Wrong SFFINDER_HOME (${SFFINDER_HOME}). Please edit the path on $0 file" 1>&2
	exit
fi

if [ ! -e "${UNIREF_DESCRIPTION}" ]; then
	echo "[ERROR] Wrong UniRef DESCRIPTION text file (${UNIREF_DESCRIPTION})" 1>&2
	exit
fi

infile=$1

if [ ! ${infile} ]; then
	echo "[ERROR] Missing input ACCs file or directory containing FASTA files (one for each Family)" 1>&2
	exit
else
	if [ ! -e ${infile} ]; then
		echo "[ERROR] Wrong input file or directory (${infile})" 1>&1
		exit
	fi
fi

outdir=$2

if [ ! ${outdir} ]; then
	echo "[ERROR] Missing output base directory" 1>&2
	exit
else
	if [ ! -e ${outdir} ]; then
		echo "[ERROR] Wrong output base directory (${outdir})" 1>&1
		exit
	fi
fi

bname=`basename $(readlink -f ${outdir})`

if [ "${bname}" == "/" ]; then
	echo "[ERROR] You can't use / as your output directory" 1>&2
	exit
fi

declare -a familyfafiles=()

indir=${infile}
if [ ! -d ${infile} ]; then
	
	mkdir -p ${outdir}/family/fa

	shopt -s nullglob

	for familyfa in ${outdir}/family/fa/*.fa; do
	    familyfafiles=("${familyfafiles[@]}" "${familyfa}")
	done
	
	if [ "${#familyfafiles[@]}" -eq "0" ]; then
		
		echo "Getting Proteins by IDs ..."

		${SFFINDER_HOME}/scripts/getProteinByID.pl 	-i ${infile} \
								-o ${outdir}/family/fa \
								1> ${outdir}/family/fa/getProgeinByID.log.out.txt \
								2> ${outdir}/family/fa/getProgeinByID.log.err.txt

	fi
	
	indir="${outdir}/family/fa"
fi
	
if [ "${#familyfafiles[@]}" -eq "0" ]; then

	for familyfa in ${indir}/*.fa; do
		familyfafiles=("${familyfafiles[@]}" "${familyfa}")
	done

	if [ "${#familyfafiles[@]}" -eq "0" ]; then
		echo "[ERROR] Not found any family fasta file" 1>&2
		exit
	fi

fi

rm -f ${outdir}/subfamily/run_sffinder_sh

for familyfa in ${indir}/*.fa; do

	familyname=`basename ${familyfa} .fa`

	mkdir -p ${outdir}/subfamily/${familyname}
	
	declare -a mlibs=()

	for mlib in ${outdir}/subfamily/${familyname}/hmms/parameters/*.mlib; do
		mlibs=("${mlibs[@]}" "${mlib}")
	done

	if [ "${#mlibs[@]}" -eq "0" ]; then
		echo "${SFFINDER_HOME}/bin/sfFinder.sh ${familyname} ${familyfa} ${outdir}/subfamily/${familyname} 1> ${outdir}/subfamily/${familyname}.sfFinder.log.out.txt 2> ${outdir}/subfamily/${familyname}.sfFinder.log.err.txt" >> ${outdir}/subfamily/run_sffinder_sh
	fi

done

if [ -e "${outdir}/subfamily/run_sffinder_sh" ]; then

	echo "Running sfFinder ..."
	
	parallel --gnu -j ${NUM_THREADS} < ${outdir}/subfamily/run_sffinder_sh &>> ${outdir}/subfamily/run_sffinder.log.all.txt 

fi

shopt -s nullglob

for famdir in ${outdir}/subfamily/*; do
	if [ -d ${famdir} ]; then
		famname=$(basename ${famdir})
		echo "Found family ${famname} ..."

		if [ ! -e "${famdir}/flowerpower/fp-workspace/final/last.subfam" ]; then
			echo "[ERROR] sfFinder.sh had some problem and did'nt generate the last.subfam file (${famdir}/flowerpower/fp-workspace/final/last.subfam)" 1>&2
			exit
		fi
		
		mkdir -p ${famdir}/treeinfo
		
		if [ ! -e "${famdir}/treeinfo/${famname}.treeinfo.txt" ]; then
			
			echo "Getting complementary attributes for trees ..."

			addTreeInfo.pl	${famdir}/flowerpower/fp-workspace/final/last.tree \
					${UNIREF_DESCRIPTION} \
					${famdir}/treeinfo/${famname}.treeinfo.txt \
					${famdir}/flowerpower/fp-workspace/final/last.subfam \
					${famdir}/uniref/${famname}.fa \
					${famdir}/flowerpower/seed.fa \
					1> ${famdir}/treeinfo/${famname}.treeinfo.log.out.txt \
					2> ${famdir}/treeinfo/${famname}.treeinfo.log.err.txt
		fi			
		
	fi
done	

mkdir -p ${outdir}/fa
mkdir -p ${outdir}/dmnd

cat ${outdir}/subfamily/*/fa/*.fa | sed 's/>\(\S\+\)\s\+\S\+\s\+\(\S\+\)/>\1.\2/' > ${outdir}/fa/${bname}.fa

if [ -e "${outdir}/fa/${bname}.fa" ]; then

	if [[ -s "${outdir}/fa/${bname}.fa" ]]; then

		if [ ! -e "${outdir}/dmnd/${bname}.dmnd" ]; then
			
			echo "Making diamond index for ${outdir}/fa/${bname}.fa ..."

			diamond makedb	--in ${outdir}/fa/${bname}.fa \
					--db ${outdir}/dmnd/${bname}.dmnd \
					1> ${outdir}/dmnd/${bname}.makedb.out.txt \
					2> ${outdir}/dmnd/${bname}.makedb.err.txt

		fi
	else
		echo "[ERROR] File ${outdir}/fa/${bname}.fa has size equal to 0 (zero)"	1>&2
		exit
	fi		
else
	echo "[ERROR] The required fasta file ${outdir}/fa/${bname}.fa was not found" 1>&2
	exit
fi


