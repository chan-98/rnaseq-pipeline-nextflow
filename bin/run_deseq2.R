#!/usr/bin/env Rscript

# # Uncomment for DEBUGGING
# output_file <- file("/usr/data/run_deseq2_logfile.txt", open = "w")
# warning_file <- file("/usr/data/run_deseq2_warnfile.txt", open = "w")
# sink(output_file, type = "output")
# sink(warning_file, type = "message")

suppressPackageStartupMessages({
    library(DESeq2)
    library(argparse)
    library(tidyverse)
    library(RColorBrewer)
    library(gplots)
})


read_counts_data <- function(input_counts_file) {
    # Extract file extension
    file_extension <- sub(".+\\.(\\w+)$", "\\1", input_counts_file)
    # Determine the seperator 
    sep <- switch(file_extension, csv = ",", tsv = "\t", NULL)

    counts_data <- read.table(input_counts_file, header = TRUE, sep = sep)

    if( "gene_id" %in% colnames(counts_data)) {
        # If count data is a double convert to integer
        dbl_columns <- sapply(counts_data, is.double)
        counts_data[dbl_columns] <- lapply(counts_data[dbl_columns], as.integer)

        # Convert the column "gene_id" to row.names and delete the column since it is redundant
        row.names(counts_data) <- counts_data$gene_id
        counts_data <- counts_data[, -1]
    } else if ("ID" %in% colnames(counts_data)) {
        # Convert the column "ID" to row.names and delete the column since it is redundant
        row.names(counts_data) <- counts_data$ID
        counts_data <- counts_data[, -1]
    }

    return(counts_data)
}

read_run_metafile <- function(run_meta_filename) {
    run_meta_in <- read.table(run_meta_filename, header = TRUE, sep = ",")
    run_meta_out <- data.frame(group = run_meta_in$group, row.names = run_meta_in$lib_name)
    return(run_meta_out) 
}

write_counts_data <- function(counts_data, output_counts_file){
    # The row.names of counts_data are the gene_ids
    gene_id_column <- data.frame(gene_id = rownames(counts_data))
    counts_data <- cbind(gene_id_column, counts_data)  
    write.table(counts_data, file = output_counts_file, sep = "\t", row.names = FALSE, quote = FALSE)
}

add_title_svg <- function(filename, title,  x = 250, y = 35, font_size = '14px', font_family = 'sans-serif', font_fill='black') {
    library(xml2)
    # Read the SVG file
    svg_content <- read_xml(filename)

    # Create a new text element
    text <- sprintf("<text x='%d' y='%d' font-size='%s' font-family='%s' fill='%s'>%s</text>",
                   x,y,font_size,font_family,font_fill,title)
    text_element <- xml2::read_xml(text)

    xml2::xml_add_child(svg_content, text_element)

    xml2::write_xml(svg_content, filename)
}

create_alldetected <- function(res, counts_data) {
    # Join the original count data to the results
    joined_data <- cbind(counts_data, res)

    # Add the gene IDs as a column
    row_names_column <- as.data.frame(row.names(joined_data))
    colnames(row_names_column) <- "ID"
    joined_data <- cbind(ID = row_names_column$ID, joined_data)

    # If the padj is NA set it to 1 following DEBrowser
    joined_data$padj[is.na(joined_data$padj)] <- 1

    # Add columns that are in DEBrowser
    joined_data$foldChange <- 2^joined_data$log2FoldChange
    joined_data$log10padj <- -log10(joined_data$padj)

   return(as.data.frame(joined_data))
}

#######################################################################################
## Added but not used 
prepGroup <- function(conds = NULL, cols = NULL, metadata = NULL, covariates = NULL) {
    if (is.null(conds) || is.null(cols)) return (NULL)
    coldata <- data.frame(cbind(cols, conds))
    coldata$conds <- factor(coldata$conds)
    colnames_coldata <- c("libname", "group")
    if(!is.null(covariates)){
        if(covariates!="NoCovariate"){
            sample_column_ind <- which(apply(metadata, 2, function(x) sum(x %in% cols) == length(cols))) 
            sample_column <- colnames(metadata)[sample_column_ind]
            covariates <- metadata[match(cols,metadata[,sample_column]), covariates, drop = FALSE]
            for(i in 1:ncol(covariates)){
                cur_covariate <- covariates[,i]
                cur_covariate <- factor(cur_covariate)
                coldata <- data.frame(cbind(coldata, cur_covariate))
                colnames_coldata <- c(colnames_coldata, paste0("covariate",i))   
            }
        }
    }
    colnames(coldata) <- colnames_coldata
    coldata
}

mrn_normalize <- function(df) {
    
    columns <- colnames(df)
    conds <- columns
    coldata <- prepGroup(conds, columns)
    df[, columns] <- apply(df[, columns], 2,
                          function(x) as.integer(x))
    dds <- DESeqDataSetFromMatrix(countData = as.matrix(df),
                                  colData = coldata, design = ~group)
    dds <- estimateSizeFactors(dds)
    norm <- counts(dds, normalized=TRUE)
    norm_df <- as.data.frame(norm)
    return(norm_df)
}
#######################################################################################

filter_and_save_csv <- function(alldetected, foldChange_cutoff, padj_cutoff, direction_change, out_directory_path) {
   
  # Filter rows based on the specified conditions
  if (direction_change == "DOWN") {
    filtered_df <- subset(alldetected, foldChange <= 1 / foldChange_cutoff & padj <= padj_cutoff)
  } else if (direction_change == "UP") {
    filtered_df <- subset(alldetected, foldChange >= foldChange_cutoff & padj <= padj_cutoff)
  } else {
    stop("Invalid direction_change value. Use 'UP' or 'DOWN'.")
  }

  # Create output directory
  if (!file.exists(out_directory_path)) {
    dir.create(out_directory_path, recursive = TRUE)
  }

  # Write the filtered data frame to a new CSV file
  output_csv_file <- file.path(out_directory_path, paste0(direction_change, ".csv"))
  write.csv(filtered_df, file = output_csv_file, row.names = FALSE)
  
  return(output_csv_file)
}

volcano_plot <- function(counts_data, title, filename){
    call <- match.call()
    function_name <- as.character(call[[1]])
    tryCatch({
        data <- counts_data[!is.na(counts_data$log2FoldChange) & !is.na(counts_data$log10padj), ]
        significant_values <- data[data$padj < 0.01, ]
        non_significant_values <- data[data$padj >= 0.01, ]

        # Calculate the number of ns rows to select (10% of total rows)
        sample_size <- round(0.1 * nrow(non_significant_values))
        sampled_data <- non_significant_values[sample(seq_len(nrow(non_significant_values)), size = sample_size, replace = FALSE), ]

        # Create the volcano plot
        volcano_plot_out <- ggplot() +
        geom_point(data = significant_values, aes(x = log2FoldChange, y = log10padj, color = factor(sign(log2FoldChange))), size = 2) +
        geom_point(data = sampled_data, aes(x = log2FoldChange, y = log10padj), color = "grey", size = 2) +
        scale_color_manual(values = c("blue", "red"), labels = c("Negative", "Positive")) +
        theme_minimal() +
        labs(x = "log2FoldChange", y = "log10 padj", title = title, color = "Fold Change Direction") +
        theme(
            panel.background = element_rect(fill = "white"),
            plot.background = element_rect(fill = "white")
        )

        ggsave(filename, volcano_plot_out, width = 8, height = 6, dpi = 300, device="png")
    }, error = function(e) {
        print(paste("Error in Function Name:", function_name))
        print(paste("Error message:", e$message))
    })
}

scatter_plot <- function(counts_data, run_meta_data, title, filename){
    call <- match.call()
    function_name <- as.character(call[[1]])
    tryCatch({
        data <- data.frame(counts_data)
        
        run_meta_data_copy <- data.frame(run_meta_data)
        # Get row names where group is equal to 'Cond1'
        run_meta_data_copy$ID <- rownames(run_meta_data_copy)
        cond1 <- run_meta_data_copy[run_meta_data_copy$group == 'Cond1', 'ID']
        cond2 <- run_meta_data_copy[run_meta_data_copy$group == 'Cond2', 'ID']

        data$cond1_log10mean <- log10(rowMeans(data[cond1], na.rm = TRUE))
        data$cond2_log10mean <- log10(rowMeans(data[cond2], na.rm = TRUE))
        
        significant_values <- data[data$padj < 0.01, ]
        non_significant_values <- data[data$padj >= 0.01, ]

        # Calculate the number of ns rows to select (10% of total rows)
        sample_size <- round(0.1 * nrow(non_significant_values))
        sampled_data <- non_significant_values[sample(seq_len(nrow(non_significant_values)), size = sample_size, replace = FALSE), ]
        
        plot_data <- rbind(significant_values, sampled_data)   
    
        png(filename = filename, width = 800, height = 600)
        
        scatter_plot_out <- plot(plot_data$cond1_log10mean, plot_data$cond2_log10mean, 
                                xlab = "cond1_log10mean", ylab = "cond2_log10mean", 
                                main = title,
                                col = "grey")  # Set the default color to grey (NS)


        # Color code the points based on the foldChange column
        for (i in 1:nrow(plot_data)) {
            if (plot_data$padj[i] < 0.01 && plot_data$log2FoldChange[i] > 0) {
                points(plot_data$cond1_log10mean[i], plot_data$cond2_log10mean[i], col = "red", pch = 19)  # Red for Up
            } else if (plot_data$padj[i] < 0.01 && plot_data$log2FoldChange[i] < 0) {
                points(plot_data$cond1_log10mean[i], plot_data$cond2_log10mean[i], col = "blue", pch = 19)  # Blue for Down
            } 
        }    

        dev.off() 
    }, error = function(e) {
        print(paste("Error in Function Name:", function_name))
        print(paste("Error message:", e$message))
    })
}

### BEGIN PCA ##############################
run_pca <- function(x=NULL, retx = TRUE, center = TRUE, scale = TRUE) {

    row_variances <- apply(x, 1, var, na.rm = TRUE)
    # Create a logical vector indicating rows with variance > 0
    non_zero_var_rows <- row_variances > 0
    # Subset the dataframe based on rows with variance > 0
    x <- subset(x, non_zero_var_rows)

    pca <- prcomp(t(x), retx = retx,
         center = center, scale. = scale)
    variances <- pca$sdev ^ 2
    explained <- variances / sum(variances)
    
    return(list(PCs = pca$x, explained = explained, pca = pca))
}

prep_pcs_data <- function(pca_data = NULL, columns_to_use = NULL){
    x <- pca_data$PCs
    plot_data <- data.frame(x)
    # Prepare data frame to pass to ggplot
    xaxis <- paste0("PC", 1)
    yaxis <- paste0("PC", 2)
    
    color  <- rownames(plot_data)
    shape <- "Conds"
    textName <- columns_to_use
    p_data <- cbind( plot_data[,c(xaxis, yaxis)], textName, color, shape)
    
    colnames(p_data) <- c("x", "y", "textName", "color", "shape")
    return(p_data)
}

pca_plot <- function(dat, run_meta_data, title, filename) {
    call <- match.call()
    function_name <- as.character(call[[1]])
    tryCatch({
        columns_to_use <- rownames(run_meta_data)
        # Keep only columns_to_use
        dat <- dat[columns_to_use]
        # Convert any character data type to double
        dat[columns_to_use] <- lapply(dat[columns_to_use], as.double)
        dat <- dat[complete.cases(dat), ]

        size <- 5
        pcx <- 1
        pcy <- 2
        pca_data <- run_pca(dat)
        p_data <- prep_pcs_data(pca_data, columns_to_use)
        color <- rownames(p_data)
        
        # Prepare axis labels
        xaxis <- sprintf("PC%d (%.2f%%)", pcx, round(pca_data$explained[pcx] * 100, 2))
        yaxis <- sprintf("PC%d (%.2f%%)", pcy, round(pca_data$explained[pcy] * 100, 2))

        plot1 <- ggplot(data=p_data, aes(x=x, y=y))
        plot1 <-  plot1 + geom_point(mapping=aes(color=color), size=3 )
        
        plot1 <- plot1 + theme(legend.title = element_blank())
        plot1 <- plot1 +  labs(x = xaxis, y = yaxis)
        
        plot1 <- plot1 + theme( plot.margin = margin(t = 1, r = 2, b = 10, l = 1, "pt"))
        plot1 <- plot1 + ggtitle(title)  +
                theme(plot.title = element_text(hjust = 0.5, face = "bold"))
        ggsave(filename, plot1, width = 5, height = 4, dpi = 300, device="png")
    }, error = function(e) {
        print(paste("Error in Function Name:", function_name))
        print(paste("Error message:", e$message))
    })

}
### END PCA ################################

### BEGIN HEATMAP ##########################
prep_heatmap_data <- function(nrm_data = NULL) {
    call <- match.call()
    function_name <- as.character(call[[1]])
    l_nrm_data <- nrm_data
    # Replace zeros with a small value
    l_nrm_data[] <- lapply(l_nrm_data, function(x) ifelse(x == 0, 0.1, x))
    l_nrm_data <- log2(l_nrm_data)
    scaled_nrm_data <- scale(t(l_nrm_data), center = TRUE, scale = TRUE)
    scaled_nrm_data <- t(scaled_nrm_data)
    return(scaled_nrm_data)
}

heatmap_plot <- function(alldetected, run_meta_data, title, filename) {
    call <- match.call()
    function_name <- as.character(call[[1]])
    tryCatch({
        significant_values <- alldetected[alldetected$padj < 0.01, ]
        non_significant_values <- alldetected[alldetected$padj >= 0.01, ]
        
        significant_values <- significant_values[, row.names(run_meta_data)]
        counts_data <- prep_heatmap_data(significant_values)

        blue_red_palette_fun <- colorRampPalette(c("blue", "white", "red"))
        blue_red_colors <- blue_red_palette_fun(256)
        png(filename, width = 800, height = 600)
        m <- heatmap.2(as.matrix(counts_data), 
                    dendrogram = "both",
                    labRow = TRUE,
                    col = blue_red_colors,
                    distfun = function(x) dist(x, method = "euclidean"),
                    hclustfun = function(x) hclust(x, method = "complete"), 
                    density.info = "none",
                    trace = "none",
                    main = title,
                    margins = c(10, 10),
                    cexCol = 1.5,
                    srtCol=45
                    ) 
        
        dev.off() 
        return(NULL)
    }, error = function(e) {
        print(paste("Error in Function Name:", function_name))
        print(paste("Error message:", e$message))
    })

}
### END HEATMAP ############################

exec_deseq <- function(input_counts_file, output_path, run_meta_filename) {
    # Get the meta data from the run meta file
    run_meta_data <- read_run_metafile(run_meta_filename)

    # Get the file name without extension from the run_meta_filename
    file_name_root <- sub("\\..*$", "", basename(run_meta_filename))

    counts_data <-read_counts_data(input_counts_file)

    # Only include data from the run_meta_data
    counts_data <- counts_data[, row.names(run_meta_data)]

    # Create the DESeqDataSet
    dds <- DESeqDataSetFromMatrix(countData = counts_data, 
                                  colData = run_meta_data, 
                                  design = ~ group)

    # Note: These are the defaults in DEBrowser
    fitType <- "parametric"
    betaPrior <- FALSE
    testType <- "LRT"

    # All othercode START
    dds <- DESeq(dds, fitType = fitType, betaPrior = betaPrior, test=testType, reduced= ~ 1)
    # All othercode END

    # # pseudo-replicates code START
    # dds <- estimateSizeFactors(dds)
    # dds <- estimateDispersionsGeneEst(dds)
    # dispersions(dds) <- mcols(dds)$dispGeneEst
    # dds <- nbinomWaldTest(dds)
    # # pseudo-replicates code END

    norm <- counts(dds, normalized=TRUE)
    res <- results(dds)

    alldetected <- create_alldetected(res, norm)
    filename <- sprintf("%s/%s_alldetected.csv", output_path, file_name_root)
    write.csv(as.data.frame(alldetected), file = filename, row.names = FALSE)

    plots_directory <- file.path(output_path, "plots")
    if (!dir.exists(plots_directory)) {
        dir.create(plots_directory, recursive = TRUE)
    }

    # Create the dispersion plot
    filename <- sprintf("%s/%s_dispersion_plot.svg", plots_directory, file_name_root)
    svg(filename, width = 8, height = 6)
    dispersion_plot <- plotDispEsts(dds)
    dev.off()
    title <- sprintf("%s Dispersion", gsub(" ", "_", file_name_root))
    add_title_svg(filename, title)
    
    # Create the volcano plot
    filename <- sprintf("%s/%s_volcano_plot.png", plots_directory, file_name_root)
    title <- sprintf("Volcano Plot ( %s )", gsub(" ", "_", file_name_root))
    volcano_plot(alldetected, title, filename)

    # Create the scatter plot
    filename <- sprintf("%s/%s_scatter_plot.png", plots_directory, file_name_root)
    title <- sprintf("Scatter Plot ( %s )", gsub(" ", "_", file_name_root))
    scatter_plot(alldetected, run_meta_data, title, filename)

    # Create the pca plot
    filename <- sprintf("%s/%s_pca_plot.png", plots_directory, file_name_root)
    title <- sprintf("PCA ( %s )", gsub(" ", "_", file_name_root))
    pca_plot(alldetected, run_meta_data, title, filename)

    # Create the heatmap plot
    filename <- sprintf("%s/%s_heatmap_plot.png", plots_directory, file_name_root)
    title <- sprintf("Heatmap ( %s )", gsub(" ", "_", file_name_root))
    heatmap_plot(alldetected, run_meta_data, title, filename)

    # Create UP DOWN Gene Sets for WormCat
    foldChange_cutoff <- 2
    padj_cutoff <- 0.01
    out_directory_path <- sprintf("%s/ud_%s", output_path, file_name_root)
    direction_changes <- c("UP", "DOWN")
 
    for (direction_change in direction_changes) {
      filter_and_save_csv(alldetected, foldChange_cutoff, padj_cutoff, direction_change, out_directory_path)
    }
}

main <- function() {
    print("Strating DESeq2 analysis")
    parser <- ArgumentParser()
    parser$add_argument("-i", "--input-counts-file", help="Counts data file")
    parser$add_argument("-o", "--output-path", help="Output directory")
    parser$add_argument("-m", "--run-meta-filename", help="File name for deseq2 meta data")

    args <- parser$parse_args()

    if (is.null(args$input_counts_file)) {
        stop("The --input-counts-file is required")
    }

    if (is.null(args$output_path)) {
        stop("The --output-path is required")
    }

    if (!file.exists(args$output_path)) {
        dir.create(args$output_path)
    }

    if (is.null(args$run_meta_filename)) {
        stop("The --run-meta-filename is required")
    }

    print(paste("exec_deseq", args$input_counts_file, args$output_path, args$run_meta_filename))
    exec_deseq(input_counts_file = args$input_counts_file,
               output_path = args$output_path,
               run_meta_filename = args$run_meta_filename)
}

test <- function() {

    print("Testing DESeq2 analysis")
    run_meta_filename <- "/usr/data/run_oxIs12_ABC16.csv"
    file_name_root <- sub("\\..*$", "", basename(run_meta_filename))
    output_path <- "/usr/data/deseq_out"

    run_meta_data <- read_run_metafile(run_meta_filename)
    alldetected <- read_counts_data("/usr/data/deseq_out/run_oxIs12_ABC16_alldetected.csv")
    print(sprintf("Number of Rows of Data %s", format(nrow(alldetected), big.mark = ",")))

    # filename <- sprintf("%s/%s_volcano_plot_test.png", output_path, file_name_root)
    # title <- sprintf("Volcano Plot ( %s )", gsub(" ", "_", file_name_root))
    # volcano_plot(alldetected, title, filename)

    # filename <- sprintf("%s/%s_scatter_plot_test.png", output_path, file_name_root)
    # title <- sprintf("Scatter Plot ( %s )", gsub(" ", "_", file_name_root))
    # scatter_plot(alldetected, run_meta_data, title, filename)

    # filename <- sprintf("%s/%s_pca_plot_test.png", output_path, file_name_root)
    # title <- sprintf("PCA ( %s )", gsub(" ", "_", file_name_root))
    # pca_plot(alldetected, run_meta_data, title, filename)

    filename <- sprintf("%s/%s_heatmap_plot.png", output_path, file_name_root)
    title <- sprintf("Heatmap ( %s )", gsub(" ", "_", file_name_root))
    heatmap_plot(alldetected, run_meta_data, title, filename)

}
#test()
main()

# # Stop capturing standard output and warnings
# sink(type = "output")
# sink(type = "message")
# close(output_file)
# close(warning_file)