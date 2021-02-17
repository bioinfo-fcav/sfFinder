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

proteinfa=$1

if [ ! ${proteinfa} ]; then
	echo "[ERROR] Missing protein fasta." 2>&1
	exit
fi

if [ ! -e ${proteinfa} ]; then
	echo "[ERROR] Wrong protein fasta (${proteinfa})." 2>&1
	exit
fi

outdir=$2

if [ ! ${outdir} ]; then
	echo "[ERROR] Missing output directory." 2>&1
	exit
fi

if [ ! -d ${outdir} ]; then
	echo "[ERROR] Wrong output directory (${outdir})." 2>&1
	exit
fi

mlibsdir=$3

if [ ! ${mlibsdir} ]; then
	echo "[ERROR] Missing *.mlib directory." 2>&1
	exit
fi

if [ ! -d ${mlibsdir} ]; then
	echo "[ERROR] Wrong *.mlib directory (${mlibsdir})." 2>&1
	exit
fi

resprefix=$4

if [ ! ${resprefix} ]; then
	echo "[ERROR] Missing result's prefix, such as \"results-hmm\"." 2>&1
	exit
fi

family=$5

if [ ! ${family} ]; then
	family=""
fi

shopt -s nullglob
for mlib in ${mlibsdir}/*.mlib; do

	name=`basename ${mlib} .mlib`
	checkres=`find ${outdir} -name "${resprefix}.*.${name}.dist"`;

	if [ ${checkres} ] && [  -e ${checkres} ]; then
		echo "Found ${checkres}. Skipping ${name} analysis !"
	else
		hmmscore ${outdir}/${resprefix} -modellibrary ${mlib} -db ${proteinfa} -sw 0 &> ${outdir}/${resprefix}.${family}.log.txt
	fi
done


