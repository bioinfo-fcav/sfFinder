#!/bin/bash

# Caminho bancos diamond
dmnd=/data/PAH-Seq/pha-families/PAHFAM_PROJECT/dmnd

# Variavel para saidas do diamond
outdmnd=/data/PAH-Seq/pha-families/PAHFAM_PROJECT/Results/dmnd

# Diamond db-subfamilias
# Metagenoma

cut -f 1,2  ${outdmnd}/subfamilies/metagenome/result-dmnd-meta.txt | \
	    sed 's/ /\t/' \
	    > ${outdmnd}/subfamilies/metagenome/result-dmnd-cleaned.tmp

mergeR.R --x="${outdmnd}/subfamilies/metagenome/result-dmnd-cleaned.tmp" \
	 --y="${dmnd}/subfamilies/ALL_subfamilies.description.txt" \
	 --by.x="V2" \
	 --by.y="V1" \
	 --noh.x \
	 --noh.y \
	 --out="${outdmnd}/subfamilies/metagenome/result-dmnd-meta-description.txt"

#rm ${outdmnd}/subfamilies/metagenome/result-dmnd-cleaned.tmp

# Referencias (Vilchez)

cut -f 1,2  ${outdmnd}/subfamilies/reference/result-dmnd-ref.txt | \
	    sed 's/ /\t/' \
	    >  ${outdmnd}/subfamilies/reference/result-dmnd-cleaned.tmp

mergeR.R --x="${outdmnd}/subfamilies/reference/result-dmnd-cleaned.tmp" \
	 --y="${dmnd}/subfamilies/ALL_subfamilies.description.txt" \
	 --by.x="V2" \
	 --by.y="V1" \
	 --noh.x \
	 --noh.y \
	 --out="${outdmnd}/subfamilies/reference/result-dmnd-ref-description.txt"

#rm ${outdmnd}/subfamilies/reference/result-dmnd-cleaned.tmp


#Diamond db-familias
#Metagenoma

cut -f1,2  ${outdmnd}/families/metagenome/result-dmnd-meta.txt | \
	   sed 's/ /\t/' \
	   > ${outdmnd}/families/metagenome/result-dmnd-cleaned.tmp

mergeR.R --x="${outdmnd}/families/metagenome/result-dmnd-cleaned.tmp" \
	--y="${dmnd}/families/ALL_families.description.txt" \
	--by.x="V2" \
	--by.y="V1" \
	--noh.x \
	--noh.y \
	--out="${outdmnd}/families/metagenome/result-dmnd-meta-description.txt"

#rm ${outdmnd}/families/metagenome/result-dmnd-cleaned.tmp

# Referencias (Vilchez)

cut -f1,2  ${outdmnd}/families/reference/result-dmnd-ref.txt | \
	   sed 's/ /\t/' \
	   > ${outdmnd}/families/reference/result-dmnd-cleaned.tmp

mergeR.R --x="${outdmnd}/families/reference/result-dmnd-cleaned.tmp" \
         --y="${dmnd}/families/ALL_families.description.txt" \
	 --by.x="V2" \
	 --by.y="V1" \
	 --noh.x \
	 --noh.y \
	 --out="${outdmnd}/families/reference/result-dmnd-ref-description.txt"

# Vrm ${outdmnd}/families/reference/result-dmnd-cleaned.tmp



