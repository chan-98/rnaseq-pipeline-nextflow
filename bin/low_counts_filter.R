#!/usr/bin/env Rscript

suppressPackageStartupMessages({
    library(argparse)
    library(tidyverse)
})

# Function to create and save histogram plot as PNG with specified fill color
log10_foldchange_plot <- function(counts_data, filename, title = "log10 Foldchange", breaks = 100, 
                                  x_label = "Values", y_label = "Frequency", fill_color = "skyblue") {

    data <- log10(rowSums(counts_data))

    tryCatch({
        png(filename, width = 800, height = 600, units = "px", res = 100)
    }, error = function(e) {
        print(paste("Error: ", e$message))
    })

    hist_counts <- hist(data, plot = FALSE, breaks = breaks)
    hist_plot <- barplot(hist_counts$counts, col = fill_color, main = title, xlab = x_label, ylab = y_label, names.arg = hist_counts$mids)
    dev.off()
}

read_counts_data <- function(input_counts_file){
    counts_data <- read.table(input_counts_file, header = TRUE, sep = "\t")

    # Convert dbl columns to integer
    dbl_columns <- sapply(counts_data, is.double)
    counts_data[dbl_columns] <- lapply(counts_data[dbl_columns], as.integer)

    # Convert the column "gene_id" to row.names and delete the column since it is redundant
    row.names(counts_data) <- counts_data$gene_id
    counts_data <- counts_data[, -1]

    return(counts_data)
}

write_counts_data <- function(counts_data, output_counts_file){
    # The row.names of counts_data are the gene_ids
    gene_id_column <- data.frame(gene_id = rownames(counts_data))
    counts_data <- cbind(gene_id_column, counts_data)  
    write.table(counts_data, file = output_counts_file, sep = "\t", row.names = FALSE, quote = FALSE)
}

exec_low_count_filter <- function(input_counts_file, output_path, low_count_filter) {

    counts_data <-read_counts_data(input_counts_file)

    title <- "log10 Foldchange before filtering"
    plot1_filename <- sprintf("%s/%s.png",output_path, gsub(" ", "_", title))
    log10_foldchange_plot(counts_data, plot1_filename, title)

    print(sprintf("Number of Rows of counts_data before filtering: %s.",format(nrow(counts_data), big.mark = ",")))
    print(sprintf("low count filter: %d.",low_count_filter))
    # Keep rows that have any column with a count value equal or >= low_count_filter
    counts_data_low_gene_count <- counts_data[rowSums(counts_data >= low_count_filter, na.rm = TRUE) > 0, ]

    print(sprintf("Number of Rows of counts_data_low_gene_count after filtering: %s.",format(nrow(counts_data_low_gene_count), big.mark = ",")))

         
    title <- "log10 Foldchange after filtering"
    plot2_filename <- sprintf("%s/%s.png",output_path, gsub(" ", "_", title))
    log10_foldchange_plot(counts_data_low_gene_count, plot2_filename, title)

    # Save the count data as a CSV file
    output_counts_file <- sprintf("%s/count_data_low_counts_filtered.tsv",output_path)
    write_counts_data(counts_data_low_gene_count, output_counts_file)

}

main <- function() {
    parser <- ArgumentParser()
    parser$add_argument("-i", "--input-counts-file", help="Counts data file")
    parser$add_argument("-o", "--output-path", help="Output directory")
    parser$add_argument("-l", "--low-count-filter", help="Low count filter")
      
    args <- parser$parse_args()

    if (is.null(args$input_counts_file)){
    stop("The --input-counts-file is required")
    }

    if (is.null(args$output_path)){
        stop("The --output-path is required")
    }

    if (!file.exists(args$output_path)) {
        dir.create(args$output_path)
    }

    if (is.null(args$low_count_filter)){
    stop("The --low-count-filter is required but can be 0")
    }
    low_count_filter_int <- as.integer(args$low_count_filter)

    print(paste("exec_low_count_filter", args$input_counts_file, args$output_path, args$low_count_filter))
    exec_low_count_filter(
        input_counts_file=args$input_counts_file, 
        output_path=args$output_path, 
        low_count_filter=low_count_filter_int)
}

main()