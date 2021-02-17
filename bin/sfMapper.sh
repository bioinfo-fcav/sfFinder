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


mapmode=$1

if [ ! ${mapmode} ]; then
	echo "[ERROR] Missing mapping mode (diamond/hmmscore)" 1>&2
	exit
else
	if [ "${mapmode}" != "diamond"  ] &&
	   [ "${mapmode}" != "hmmscore" ]; then
		echo "[ERROR] Wrong mapping mode (${mapmode}) choose one of the two options (diamond/hmmscore)" 1>&1
		exit
	fi
fi


qfile=$2

if [ ! ${qfile} ]; then
	echo "[ERROR] Missing query fasta file" 1>&2
	exit
else
	if [ ! -e ${qfile} ]; then
		echo "[ERROR] Wrong query file (${qfile})" 1>&1
		exit
	fi
fi

dbdir=$3

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

if [ "${mapmode}" == "diamond" ]; then
	
	if [ ! -e "${dbdir}/dmnd/${bname}.dmnd" ]; then
		echo "[ERROR] Not found required diamond index (${dbdir}/dmnd/${bname}.dmnd). Please, run mkFProfiles.sh" 1>&2
		exit
	fi
	
	echo "Running sfMapper.sh using \"diamond\" mode ..."
	
	mkdir -p ${outdir}/tmp
	

	if [ ! -e "${outdir}/${bname}.txt" ]; then

		rnum=${RANDOM}
		diamond blastp	--query ${qfile} \
			--threads ${NUM_THREADS} \
			--db ${dbdir}/dmnd/${bname}.dmnd \
			--outfmt 100 \
			--max-target-seqs 1 \
			--evalue 1e-5 \
			--query-cover 80 \
			--ultra-sensitive \
			--id 20 \
			--tmpdir ${outdir}/tmp/ \
			--out ${outdir}/${rnum}.diamond \
		1> ${outdir}/${rnum}.diamond.log.out.daa \
		2> ${outdir}/${rnum}.diamond.log.err.txt	

		diamond view --daa ${outdir}/${rnum}.diamond.daa --outfmt 6 qseqid sseqid > ${outdir}/${bname}.txt
	fi
	
	# Formatting preliminary results
	echo -e "#QueryId\tFamily\tSubfamily" > ${outdir}/diamond.result.0.txt

	cat ${outdir}/${bname}.txt | perl -F"\t" -lane 'my (@term)=split(/\./, $F[1]); print join("\t", $F[0], $term[$#term-1], $term[$#term]);' >> ${outdir}/diamond.result.0.txt
	

elif [ "${mapmode}" == "hmmscore" ]; then
	
	echo "Running sfMapper.sh using \"hmmscore\" mode ..."
	
	${SFFINDER_HOME}/scripts/run_hmmscore.pl -i ${qfile} \
						 -o ${outdir} \
						 -b ${dbdir}/subfamily \
						 -p ${bname} \
						 1> ${outdir}/run_hmmscore.log.out.txt \
						 2> ${outdir}/run_hmmscore.log.err.txt

	# Formatting preliminary results
	${SFFINDER_HOME}/scripts/evalHMMresults.pl	-p ${bname} \
							-t -100 \
							-i ${outdir} \
							-o ${outdir}/hmmscore.result.0.txt \
							1> ${outdir}/evalHMMresults.log.out.txt \
							2> ${outdir}/evalHMMresults.log.err.txt

else
	echo "[ERROR] Wrong mapping mode (${mapmode}) choose one of the two options (diamond/hmmscore)" 1>&1
	exit
fi

${SFFINDER_HOME}/scripts/addTreeInfo.pl -i ${outdir}/${mapmode}.result.0.txt \
					-d ${dbdir} \
					-o ${outdir}/${mapmode}.result.1.txt \
					1> ${outdir}/${mapmode}.result.log.out.txt \
					2> ${outdir}/${mapmode}.result.log.err.txt \


