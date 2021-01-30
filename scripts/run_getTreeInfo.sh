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
#  Copyright (C) 2018  Universidade Estadual Paulista - UNESP
#
#  Universidade Estadual Paulista "Júlio de Mesquita Filho"
#  Laboratório de Bioinformática
#
#  Michelli Inácio Gonçalves Funnicelli 
#  michelligf@gmail.com
#

indir=$1
#${base_dir}/Uniref/alignments

path_indir=`realpath ${indir}`

for dir in `ls -d ${indir}/*`; do

        dir_name=`basename $dir`


        if [ -d "${dir}" ]; then
		
#		echo $dir_name  
		echo $dir		

#		cd ${dir}/fp-workspace/final/
		
		getTreeInfo.pl ${dir}/fp-workspace/final/last.tree \
				   /data/db/uniprot/uniref100_prok_cleaned.txt \
				   ${dir}/fp-workspace/final/$dir_name'.treeinfo.txt' \
				   ${dir}/fp-workspace/final/last.subfam \
				   ${dir}/msa.fa \
				   ${dir}/seed.fa \
				   &> ${dir}/fp-workspace/final/treeinfo.out
	

#	getTreeInfo.pl /data/PAH-Seq/pha-families/PAHFAM_PROJECT/Uniref/alignments/INDO/fp-workspace/final/last.tree 
#	/data/db/uniprot/uniref100_prok_cleaned.txt
#       	treeinfo.txt 
#	/data/PAH-Seq/pha-families/PAHFAM_PROJECT/Uniref/alignments/INDO/fp-workspace/final/last.subfam 
#       	/data/PAH-Seq/pha-families/PAHFAM_PROJECT/Uniref/alignments/INDO/msa.fa 
#	/data/PAH-Seq/pha-families/PAHFAM_PROJECT/Uniref/alignments/INDO/seed.fa > INDO.log
#

#		cd ${path_indir}
        fi
done
