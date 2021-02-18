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

mkdir -p ../example/output

#To run mkFProfiles.sh using a list of proteins from two families for profiles identification
./mkFProfiles.sh ../example/test.txt ../example/output

mkdir -p ../example/mapping

#To run sfMapper.sh using "hmmscore" mode for mapping family/subfamily information
./sfMapper.sh hmmscore ../example/TEST.fa ../example/output ../example/mapping
#To run sfMapper.sh using "diamond" mode for mapping family/subfamily information
./sfMapper.sh diamond ../example/TEST.fa ../example/output ../example/mapping

#To combine results of sfMapper.sh results using diamond and hmmscore modes
./sfCombine.sh ../example/TEST.fa ../example/output ../example/mapping ../example/mapping

