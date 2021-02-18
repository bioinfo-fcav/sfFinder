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


if [ ! ${SFFINDER_HOME} ]; then
	echo "[ERROR] Please set SFFINDER_HOME within $0 script" 1>&2
	exit
fi

if [ ! -e "${SFFINDER_HOME/bin/sfMapper.sh}" ]; then
	echo "[ERROR] Wrong SFFINDER_HOME (${SFFINDER_HOME}). Please edit the path on $0 file" 1>&2
	exit
fi

qfile=$1

if [ ! ${qfile} ]; then
	echo "[ERROR] Missing query fasta file" 1>&2
	exit
else
	if [ ! -e ${qfile} ]; then
		echo "[ERROR] Wrong query file (${qfile})" 1>&1
		exit
	fi
fi

absqfile=`readlink -f ${qfile}`

number_of_inputted_proteins=`grep -c '^>' ${qfile}`
if [ ! ${number_of_inputted_proteins} ]; then
	number_of_inputted_proteins=0
fi
if [ ${number_of_inputted_proteins} == 0 ]; then
	echo "[ERROR] Not found any protein in query file (${qfile}) or not in FASTA format" 1>&2
	exit
fi

dbdir=$2

if [ ! ${dbdir} ]; then
	echo "[ERROR] Missing database directory" 1>&2
	exit
else
	if [ ! -e ${dbdir} ]; then
		echo "[ERROR] Wrong database directory (${dbdir})" 1>&1
		exit
	fi
fi

bname=`basename $(readlink -f ${dbdir})`

if [ "${bname}" == "/" ]; then
	echo "[ERROR] You can't use / as your database directory" 1>&2
	exit
fi

mapdir=$3

if [ ! ${mapdir} ]; then
	echo "[ERROR] Missing mapping directory" 1>&2
	exit
else
	if [ ! -e ${mapdir} ]; then
		echo "[ERROR] Wrong mapping directory (${mapdir})" 1>&1
		exit
	fi
fi

if   [ ! -e "${mapdir}/diamond.result.1.txt"  ]; then
	echo "[ERROR] Cannot find diamond.result.1.txt" 1>&2
	exit
elif [ ! -e "${mapdir}/hmmscore.result.1.txt" ]; then
	echo "[ERROR] Cannot find hmmscore.result.1.txt" 1>&2
	exit
else
	echo -e "::: Found both results in mapping directory (${mapdir}).\n    * Please, certify that this is the right mapping directory for the related queried file (${qfile}).\n\n    Proceeding with evaluation ... \n"
fi


outdir=$4

if [ ! ${outdir} ]; then
	echo "[ERROR] Missing output directory" 1>&2
	exit
else
	if [ ! -e ${outdir} ]; then
		echo "[ERROR] Wrong output directory (${outdir})" 1>&1
		exit
	fi
fi


mergeR.R --x="${mapdir}/diamond.result.1.txt" \
	 --y="${mapdir}/hmmscore.result.1.txt" \
	 --by.x='X.QueryId' \
	 --by.y='X.QueryId' \
	 --out=${outdir}/combined.result.1.txt \
	 --all.x \
	 --all.y \
	 --print.out.label \
	 1> ${outdir}/combined.mergeR.log.out.txt \
	 2> ${outdir}/combined.mergeR.log.err.txt 

${SFFINDER_HOME}/scripts/evalCombination.pl	-i ${outdir}/combined.result.1.txt \
						-q ${absqfile} \
						-o ${outdir}/combined.result.2.txt \
						1> ${outdir}/combined.evalCombination.log.out.txt \
						2> ${outdir}/combined.evalCombination.log.err.txt

mfile=${outdir}/combined.result.2.txt
absmfile=`readlink -f ${outdir}/combined.result.2.txt`

echo -e "# Mapping Summary"
echo -e "Input file.................................: ${absqfile}"
echo -e "Mapping mode...............................: combined"
echo -e "Mapping file...............................: ${absmfile}"
echo -e "Number of inputted proteins................: ${number_of_inputted_proteins}"
#f00s00	
#Not found family&subfamily.................: 
#f10s10
#Found family&subfamily only by diamond.....: 
#f01s01
#Found family&subfamily only by hmmscore....:
#f11s11
#Found a consensus for family&subfamily.....:
#f11s12
#Found a consensus only for family..........:
#f12s12
#Not found a consensus for family&subfamily.:
grep -v '^X.QueryId' ${absmfile} | cut -f 2 | sort | uniq -c | sed 's/^ \+//' | awk 'BEGIN { FS=" "; OFS=" "; } { print $2,$1 }' | \
	sed 's/^f00s00/Not found family\&subfamily.................:/' | \
	sed 's/^f10s10/Found family\&subfamily only by diamond.....:/' | \
	sed 's/^f01s01/Found family\&subfamily only by hmmscore....:/' | \
	sed 's/^f11s11/Found a consensus for family\&subfamily.....:/' | \
	sed 's/^f11s12/Found a consensus only for family..........:/'  | \
	sed 's/^f12s12/Not found a consensus for family\&subfamily.:/'


