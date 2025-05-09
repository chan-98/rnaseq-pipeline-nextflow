
process FASTQC{
    tag "FASTQC on $sample_id"
    label 'process_medium'
    container 'chandiniv/qc-tools:1.0.1'
    publishDir "${params.results_dir}/fastqc", mode:'copy'

    input:
    tuple val(sample_id), path(reads)

    output:
    path "${sample_id}_logs" 

    script:
    """
    mkdir -p ${sample_id}_logs
    fastqc -o ${sample_id}_logs -f fastq -q ${reads}
    """
}

process FASTQC_SINGLE {
    tag "FASTQC on ${reads.getName().split("\\.")[0]}"
    label 'process_medium'
    container 'chandiniv/qc-tools:1.0.1'
    publishDir "${params.results_dir}/fastqc", mode:'copy'

    input:
    path reads

    output:
    path "${reads.getName().split("\\.")[0]}_logs" 

    script:
    def file_name_prefix = reads.getName().split("\\.")[0]
    """
    mkdir ${file_name_prefix}_logs
    fastqc -o ${file_name_prefix}_logs -f fastq -q ${reads}
    """
}

process DESEQ_REPORT {
    label 'process_low'
    container 'chandiniv/qc-tools:1.0.1'
    publishDir params.results_dir, mode:'copy'

    input:
    path report_config
    path ('*')
    
    output:
    path "deseq_report.pdf"

    script:
    """
    cp -r ${projectDir}/assests/md_to_pdf/* ./results
    cp -r ${launchDir}/data/wormbase/*.geneIDs.csv ./results
    cp ${report_config} ./results
    cd results
    deseq_report.py --report-config "${report_config}" --input-path .
    cd -
    cp ./results/deseq_report.pdf ./deseq_report.pdf 
    """

}


process OVERVIEW_REPORT {
    label 'process_low'
    container 'chandiniv/qc-tools:1.0.1'
    publishDir params.results_dir, mode:'copy'

    input:
    path report_config
    
    output:
    path "overview_report.pdf"

    script:
    """
    cp -r ${projectDir}/assests/md_to_pdf/* .
    overview_report.py --report-config "${report_config}"
    """
}

process STAGE_RESULTS {
    label 'process_low'
    container 'chandiniv/qc-tools:1.0.1'
    publishDir launchDir, mode:'copy'

    input:
    path results_dir
    path data_dir
    val  output_path 
    path ignored
    
    output:
    path "${output_path}"

    script:
    """
    mkdir -p "${output_path}"
    stage_results.sh ${results_dir} ${data_dir} ${output_path}
    """
}

