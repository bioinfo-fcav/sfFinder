# sfFinder

*s*ub-*f*amily *Finder*: Finds similar family protein sequences in UniRef database, and, also generates HMM profiles and Fasta sequences from identified subfamilies. The profiles can be used to prospect new proteins from that family in metagenomic datasets using the HMMs through SAM package or the Fasta sequences through similarity searches through DIAMOND aligner.

## Dependencies

- GNU Parallel (https://www.gnu.org/software/parallel/);
- NCBI E-Utilities (https://www.ncbi.nlm.nih.gov/books/NBK25501/);
- DIAMOND (https://uni-tuebingen.de/fakultaeten/mathematisch-naturwissenschaftliche-fakultaet/fachbereiche/informatik/lehrstuehle/algorithms-in-bioinformatics/software/diamond/);
- BLAST+ (https://blast.ncbi.nlm.nih.gov/Blast.cgi?PAGE_TYPE=BlastDocs&DOC_TYPE=Download);
- pullseq (https://github.com/bcthomas/pullseq);
- flowerpower (http://phylogenomics.berkeley.edu/software);
- BPG_utilities (http://phylogenomics.berkeley.edu/software);
- SCI-PHY version 1 (http://phylogenomics.berkeley.edu/software);
- T-Coffee (http://tcoffee.crg.cat/);
- SAM: Sequence Alignment and Modeling Software System (http://www.soe.ucsc.edu/research/compbio/sam.html)
- Python2 (https://www.python.org/download/releases/2.7/);
- Python2 package biopython==1.54 [ATTENTION: Doesn't work with Python >= 1.55] (https://pypi.org/project/biopython/1.54/);
- Python2 package pygres (https://pypi.org/project/pygres/);
- Perl Carp package (https://metacpan.org/pod/Carp);
- Perl Log::Log4perl package (https://metacpan.org/pod/Log::Log4perl);
- Perl Readonly package https://metacpan.org/pod/Readonly);

## Installation

- Unpack flowerpower.tar.gz:
```bash=
tar -zxvf flowerpower.tar.gz
```
- Copy the update patch (flowerpower.patch) to the flowerpower directory and apply the patch:
```bash=
patch -s -p0 < flowerpower.patch
```
- The 
- Change mode of Perl (\*.pl) and Python (\*.py) scripts on flowerpower directory:
```bash=
chmod a+x *.pl *.py
```
- Verify if all the executable paths are on $PATH environment variable;
- Create a symlink for BPG_utilities/bpg and BPG_utilities/pfacts003 in flowerpower directory (must be in the $PATH);
- Create a symlink for BPG_utilities/make_nr_at_100_with_dict.py in flowerpower directory (must be in the $PATH);
- Create a symlink for BPG_utilities/make_nr_at_100_with_dict.py in flowerpower directory (must be in the $PATH);


## Input

# sfFinder.sh

The input is the protein family name, the formatted protein sequence(s) fasta file and the output directory:

```bash=
sfFinder.sh FamilyName /path_to/FamilyProteins.fa /path_to/output/FamilyName
```

If you don't have a fasta file, but only the accession numbers, you can use *esearch* from NCBI e-utilities:

For example:
```bash=
rm -f ./family.fa
esearch -db protein -query BAB33284.1 | efetch -db protein -format fasta >> ./ALKB.fa
esearch -db protein -query ABM79805.1 | efetch -db protein -format fasta >> ./ALKB.fa
```

... or use the script "scripts/getProteinByID.pl" for this kind of entry:

:::
>ALKB_gi|89889739|ref|ZP_01201250.1| alkane-1-monooxygenase [Flavobacteria bacterium BBFL7]
>ALKB_gi|13358852|dbj|BAB33284.1| alkane hydroxylase A [Acinetobacter sp. M-1]
>ALKB_gi|13358856|dbj|BAB33287.1| alkane hydroxylase B [Acinetobacter sp. M-1]
>ALKB_gi|123967456|gb|ABM79805.1| oxygenase component of xylene monooxygenase [Sphingobium yanoikuyae]
>ALKB_gi|37360912|dbj|BAC98365.1| alkane hydroxylase [Alcanivorax borkumensis]
:::

```bash=
./scripts/getProteinByID.pl -i /path_to/familyentries.txt /path_to/outdir
ls /path_to/outdir/ALKB.fa
```

# mkFamiliesProfiles.sh

If you prefer, for multiple family entries, you can use the following pipeline to execute automatically the 
getProteinByID.pl and, also, generates the profiles using sfFinder.sh:

```bash=
mkFamiliesProfiles.sh /path_to/familyentries.txt
```
