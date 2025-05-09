#!/usr/bin/env Rscript

suppressPackageStartupMessages({
    library(tximport)
    library(argparse)
    library(tidyverse)
})


exec_tximport <- function(input_path, output_path, tx2gene, counts_method) {  
    samples <- list.files(path = input_path, full.names = T, pattern="^salmon_expression")
    files <- file.path(samples, "quant.sf")
    
    names(files) <- str_replace(samples, input_path, "") %>%
                    str_replace("/salmon_expression_", "")
    tx2gene <- read.delim(tx2gene)
    
    txi <- tximport(files, type = "salmon", tx2gene = tx2gene, countsFromAbundance = counts_method)

    counts_data <- txi$counts %>% round() %>% data.frame()
    gene_id <- row.names(counts_data)
    counts_data <- cbind(gene_id, counts_data)
    write.table(counts_data, file=sprintf("%s/%s_counts.tsv", output_path, tolower(counts_method)), row.names=FALSE, quote=FALSE, sep='\t')


    abundance_data <- txi$abundance %>% round(digits = 3) %>% data.frame()
    gene_id <- row.names(abundance_data)
    abundance_data <- cbind(gene_id, abundance_data)
    write.table(abundance_data, file=sprintf("%s/%s_abundance.tsv", output_path, tolower(counts_method)), row.names=FALSE, quote=FALSE, sep='\t')

    length_data <- txi$length %>% round(digits = 3) %>% data.frame()
    gene_id <- row.names(length_data)
    length_data <- cbind(gene_id, length_data)
    write.table(length_data, file=sprintf("%s/%s_length.tsv", output_path, tolower(counts_method)), row.names=FALSE, quote=FALSE, sep='\t')
}
main <- function() {
      parser <- ArgumentParser()
      parser$add_argument("-i", "--input-path", help="Location to search for quant.sf files")
      parser$add_argument("-o", "--output-path", help="Output directory")
      parser$add_argument("-t", "--tx2gene", help="tx2gene mapping file")
      parser$add_argument("-m", "--counts-method", default="lengthScaledTPM", help="Method tximport uses for counts generation")

      args <- parser$parse_args()

      if (is.null(args$input_path)){
        stop("The --input-path is required")
      }

     if (is.null(args$output_path)){
        stop("The --output-path is required")
      }

     if (is.null(args$tx2gene)){
        stop("The --tx2gene mapping file is required")
      }
      print(paste("XXXXX exec_tximport", args$input_path, args$output_path, args$tx2gene, args$counts_method))
      exec_tximport(
        input_path=args$input_path, 
        output_path=args$output_path, 
        tx2gene=args$tx2gene, 
        counts_method=args$counts_method)

}

main()

