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

basedir=/data/PAH-Seq/pha-families/PAHFAM_PROJECT/

mkdir -p ${basedir}/hmm_models/

#for dir in `ls -d ${indir}/*`; do
#
#        dir_name=`basename ${dir}`
#
#        if [ -d "${dir}" ]; then
#
#                mkdir -p ${basedir}/hmm_models/${dir_name}
#                cp ${dir}/fp-workspace/final/last.*.mod ${basedir}/hmm_models/${dir_name}
#
#        fi
#
#done


mkdir -p ${modelsdir}/calibrated

${basedir}/scripts/sam_t2k-calibrate.pl ${basedir}/hmm_models/ ${basedir}/hmm_models/calibrated

