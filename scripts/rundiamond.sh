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


mkdir -p /data/PAH-Seq/pha-families/PAHFAM_PROJECT/dmnd/

dmnd=/data/PAH-Seq/pha-families/PAHFAM_PROJECT/dmnd/

mkdir -p ${dmnd}/subfamilies 

indir=/data/PAH-Seq/pha-families/PAHFAM_PROJECT/Uniref/alignments/

for dir in `ls -d ${indir}/*`; do
        if [ -d "${dir}" ]; then
                fname=`basename ${dir}`
                echo $fname

		sed 's/^\(>.*\)$/\1\t'${fname}'/' ${dir}/fp-workspace/final/final.fa > ${dmnd}/subfamilies/${fname}.fa

		cut -f1,3 ${dir}/fp-workspace/final/${fname}.treeinfo.txt | sed '/#taxa/d' >>  ${dmnd}/subfamilies/subfamilies.txt
		
        fi
done

cat ${dmnd}/subfamilies/*.fa > ${dmnd}/subfamilies/ALL_subfamilies.fasta

grep ">" ${dmnd}/subfamilies/ALL_subfamilies.fasta | sed 's/>//; s/ //' > ${dmnd}/subfamilies/families.txt


mergeR.R --x="${dmnd}/subfamilies/subfamilies.txt" --y="${dmnd}/subfamilies/families.txt" --noh.x --noh.y --by.x="V1" --by.y="V1" --out="${dmnd}/subfamilies/ALL_subfamilies.description.txt"

diamond makedb --in ${dmnd}/subfamilies/ALL_subfamilies.fasta --db ${dmnd}/subfamilies/ALL_subfamilies

# Arquivo de descrição

#grep ">" ${dmnd}/subfamilies/ALL_subfamilies.fasta | sed 's/ /\t/' | sed 's/>//' >  ${dmnd}/subfamilies/ALL_subfamilies.description.txt

mkdir -p ${dmnd}/families

indir2=/data/PAH-Seq/pha-families/PAHFAM_PROJECT/Uniref/

for file in `ls ${indir2}/*.fa`; do
        fname=`basename ${file} .fa`
        echo $fname
        sed 's/ .*$//' ${file} | sed 's/^\(>.*\)$/\1\t'${fname}'/' > ${dmnd}/families/${fname}.fa
done

cat ${dmnd}/families/*.fa > ${dmnd}/families/ALL_families.fasta

diamond makedb --in ${dmnd}/families/ALL_families.fasta --db ${dmnd}/families/ALL_families

grep ">" ${dmnd}/families/ALL_families.fasta | sed 's/ /\t/' | sed 's/>//' >  ${dmnd}/families/ALL_families.description.txt


# Criando os diretorios de resultados alinhamento diamond (db subfamilies flowerpower)
mkdir -p /data/PAH-Seq/pha-families/PAHFAM_PROJECT/Results/dmnd/subfamilies/metagenome
mkdir -p /data/PAH-Seq/pha-families/PAHFAM_PROJECT/Results/dmnd/subfamilies/reference


# Criando os diretorios de resultados alinhamento hmms (samt2k) (db subfamilies flowerpower)
mkdir -p /data/PAH-Seq/pha-families/PAHFAM_PROJECT/Results/hmms/subfamilies/metagenome
mkdir -p /data/PAH-Seq/pha-families/PAHFAM_PROJECT/Results/hmms/subfamilies/reference


# Criando os diretorios de resultados alinhamento diamond (db families sequencias VILCHEZ)
mkdir -p /data/PAH-Seq/pha-families/PAHFAM_PROJECT/Results/dmnd/families/metagenome
mkdir -p /data/PAH-Seq/pha-families/PAHFAM_PROJECT/Results/dmnd/families/reference


# Criando os diretorios de resultados alinhamento hmms (samt2k) (db families sequencias VILCHEZ)
mkdir -p /data/PAH-Seq/pha-families/PAHFAM_PROJECT/Results/hmms/families/metagenome
mkdir -p /data/PAH-Seq/pha-families/PAHFAM_PROJECT/Results/hmms/families/reference

# orfs preditas no metagenoma
orfs=/data/PAH-Seq/pha-families/PAHFAM_PROJECT/prokka_filtered.faa

# Sequencias Vilchez
refs=/data/PAH-Seq/pha-families/PAHFAM_PROJECT/Families/concatenated/ALL.fa 

# Variavel para saidas do diamond
outdmnd=/data/PAH-Seq/pha-families/PAHFAM_PROJECT/Results/dmnd

# Diamond db-subfamilias
# Metagenoma 
diamond blastp --threads 40 --db ${dmnd}/subfamilies/ALL_subfamilies.dmnd --out ${outdmnd}/subfamilies/metagenome/result-dmnd-meta.txt --outfmt 6 --query ${orfs} -k 1 --evalue 1e-5 --id 30 --query-cover 90 --more-sensitive

# Referencias (Vilchez)
diamond blastp --threads 40 --db ${dmnd}/subfamilies/ALL_subfamilies.dmnd --out ${outdmnd}/subfamilies/reference/result-dmnd-ref.txt --outfmt 6 --query ${refs} -k 1 --evalue 1e-5 --id 30 --query-cover 90 --more-sensitive

#Diamond db-familias
# Metagenoma
diamond blastp --threads 40 --db ${dmnd}/families/ALL_families.dmnd --out ${outdmnd}/families/metagenome/result-dmnd-meta.txt --outfmt 6 --query ${orfs} -k 1 --evalue 1e-5 --id 30 --query-cover 90 --more-sensitive

# Referencias (Vilchez)
diamond blastp --threads 40 --db ${dmnd}/families/ALL_families.dmnd --out ${outdmnd}/families/reference/result-dmnd-ref.txt --outfmt 6 --query ${refs} -k 1 --evalue 1e-5 --id 30 --query-cover 90 --more-sensitive

/data/PAH-Seq/pha-families/PAHFAM_PROJECT/scripts/get-results-dmnd.sh
