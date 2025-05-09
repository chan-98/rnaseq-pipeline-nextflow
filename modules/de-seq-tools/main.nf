
process TX2GENE {
    label 'process_low'
    tag "$transcriptome.simpleName"
    container 'chandiniv/de-seq-tools:1.0.1'
    publishDir params.results_dir, mode:'copy'

    input:
    path transcriptome 

    output:
    path "salmon_transcripts/tx2gene.tsv" , emit: tx2gene_tsv

    script:
    """
    mkdir -p salmon_transcripts
    tx2gene_map.py --input-file ${transcriptome} --output-file salmon_transcripts/tx2gene.tsv
    """
}

process TXIMPORT_COUNTS {
    label 'process_low'
    container 'chandiniv/de-seq-tools:1.0.1'
    publishDir params.results_dir, mode:'copy'

    input:
    path('*')
    path tx2gene
    val count_method 

    output:
    path "salmon_summary"

    script:
    """
    mkdir -p salmon_summary
    tx_import.R --input-path . --output-path salmon_summary --tx2gene ${tx2gene} --counts-method ${count_method}
    """
}

process LOW_COUNT_FILTER {
    label 'process_low'
    container 'chandiniv/de-seq-tools:1.0.1'
    publishDir params.results_dir, mode:'copy'

    input:
    path counts_file
    val low_count_max 

    output:
    path "low_count_summary"
    env file_nm, emit: low_count_file
    

    script:
    """
    mkdir -p low_count_summary
    touch low_count_summary/count_data_low_counts_filtered.tsv
    file_nm=\$(readlink -f low_count_summary/count_data_low_counts_filtered.tsv)
    low_counts_filter.R --input-counts-file ${counts_file} --output-path low_count_summary --low-count-filter ${low_count_max}
    """
}

process DESEQ_EXEC {
    label 'process_medium'
    container 'chandiniv/de-seq-tools:1.0.1'
    publishDir params.results_dir, mode:'copy'

    input:
    val low_counts_file
    path deseq_meta_file 

    output:
    path "deseq_${deseq_meta_file.getName().split("\\.")[0]}"
    
    

    script:
    """
    mkdir -p deseq_${deseq_meta_file.getName().split("\\.")[0]}
    run_deseq2.R --input-counts-file ${low_counts_file} \
                                  --output-path deseq_${deseq_meta_file.getName().split("\\.")[0]} \
                                  --run-meta-filename ${deseq_meta_file}
    """
}

process GET_DROPBOX_DATA {
    label 'process_low'
    container 'chandiniv/de-seq-tools:1.0.1'
    publishDir params.data_dir, mode:'copy'

    input:
        val data_remote 
        val data_local

    output:
        path "${data_local}", emit: data_local_dir

    script:
        """
        mkdir -p "${data_local}"
        get_dropbox_data.sh "${data_remote}" "${data_local}"
        """    
}


process CHECK_MD5 {
    label 'process_low'
    container 'chandiniv/de-seq-tools:1.0.1'
    publishDir params.results_dir, mode:'copy'

    input:
        path data_local
    
    output:
        path "md5_report.html"

    script:
        """
        check_md5.py "${data_local}"
        """

}


