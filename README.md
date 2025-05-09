# RNA-Seq Analysis

## Introduction

This repository utilizes Nextflow to create a reproducable bioinformatics pipeline built specifically for a *C. elegans* RNA sequencing (Illumina) analysis project.

The pipeline takes FASTQ files as input, performs initial MD5 checks, quality control (QC) checks, trimming, and alignment, and produces a gene expression matrix, QC reports, and gene set enrichment data.



## Pipeline Process

* 1a. Get FASTQ data from Dropbox and move it to the HPC (`get_dropbox_data-<PI_NAME>.nf`)
* 1b. Check the MD5 Checksum values of the transferred data (`check_md5.py`)
* 2a. Update Wormbase GeneIDs based on Version Number (e.g.,WS289) (`utility/wormbase_download.sh`, `create_star_rsem_index.nf`, `create_salmon_index.nf`) 
* 2b. Get genome/transcript data from Wormbase for alignment (`utility/wormbase_download.sh`)
* 3a. Create STAR and rsem indexes (`create_star_rsem_index.nf`)
* 3b. Create Salmon index file (`create_salmon_index.nf`)
     * NOTE Salmon process is currently used for testing and validation only
* 4a. Execute Quality Control on FASTQ Data (`rnaseq-rsem-<PI_NAME>.nf`)
* 4b. Align FASTQ data to the Worm Genome
* 4c. Quantify the Gene Expression
* 4d. Summarize results for further analysis
* 4e. Aggregate the QC Reports for simplified review
* 5a. Execute DEBrowser to perform Differential Expression Analysis (`utility/start_debrowser.sh`)
* 5b. Trim Data as needed
* 5c. Produce heatmap visualizations  
* 6a. Execute Wormcat Batch (`wormcat_batch.nf`)


## Pipeline Outputs

* MD5 Checksum Report
* FAST QC Reports
* Multi QC Report
* Isoform Quantification
* Gene Quantification
* DESeq2 heatmap visualizations 
* Wormcat annotations and visualization of gene set enrichment data
