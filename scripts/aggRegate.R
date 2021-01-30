#!/usr/bin/env Rscript

args <- commandArgs(TRUE)

## Default setting when no arguments passed
if(length(args) < 1) {
          args <- c("--help")
}

## Help section
if("--help" %in% args) {
  cat("
      aggRegate.R - Aggregate data.frame
 
      Arguments:
      --infile=someValue       - input file path
      --formula=someValue      - formula
      --noh                    - input file doesn't have header
      --help                   - print this Help
      --out=someValue          - output file

      Example:
      ./aggRegate.R --infile=\"input1.txt\" --noh --formula=\"V1 ~ V2\" --output=\"output.txt\"
      
      Daniel Guariz Pinheiro
      FCAV/UNESP - Univ Estadual Paulista
      dgpinheiro@gmail.com
      \n\n")

  q(save="no")
}


## Parse arguments (we expect the form --arg=value)
parseArgs <- function(x) strsplit(sub("^--", "", x), "=")
argsDF <- as.data.frame(do.call("rbind", parseArgs(args)))
argsL <- as.list(as.character(argsDF$V2))
names(argsL) <- argsDF$V1

if(is.null(argsL[['infile']])) {
        sink(stderr())
        cat("\nERROR: Missing input file !\n\n")
        sink()
        q(save="no")
}

if(is.null(argsL[['formula']])) {
        sink(stderr())
        cat("\nERROR: Missing formula !\n\n")
        sink()
        q(save="no")
}

if(is.null(argsL[['noh']])) {
	argsL[['noh']] = FALSE
} else {
	argsL[['noh']] = TRUE
}

if(is.null(argsL[['out']])) {
        sink(stderr())
        cat("\nERROR: Missing output file !\n\n")
        sink()
        q(save="no")
}

bm.df <- read.delim(argsL[['infile']], header=argsL[['noh']], stringsAsFactors=FALSE, sep="\t")

ag.bm.df <- aggregate( formula(argsL[['formula']]) , FUN=function(x) {return(paste(x, collapse = ","))}, data=bm.df )

write.table(x=ag.bm.df, file=argsL[['out']], col.names=FALSE, row.names=FALSE, quote=FALSE, sep="\t")

