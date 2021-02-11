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

