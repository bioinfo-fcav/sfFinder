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

indir=$1

for file in `ls ${indir}/*.aln`; do

	# Extrai basename
	bn=`basename ${file} .aln`

	# Cria a pasta
        mkdir -p ${indir}/${bn}

        cp ${file} ${indir}/${bn}/
done

source activate flowerpower

basedir=`pwd`
for dir in `ls -d ${indir}/*`; do
	if [ -d "${dir}" ]; then
		cd ${dir}
		flowerpower.pl -a ${dir}.aln -d /data/db/uniprot/uniref100_prok_cleaned --tempcheck 1 > ${dir}/flowerpower.out
		cd ${basedir}
	fi
done

source deactivate

