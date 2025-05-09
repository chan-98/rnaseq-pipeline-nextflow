process RSEM_INDEX {
    label 'process_medium'
    container "chandiniv/star-rsem:1.0.1"
    publishDir params.results_dir, mode:'copy'

    input:
    path genome_file
    path annotation_file 

    output:
    path 'rsem_index' 

    script:
    """
    mkdir -p ./rsem_index
    rsem-prepare-reference \
        --gtf ${annotation_file} \
        ${genome_file} \
        ./rsem_index/rsem
    """
}

process RSEM_QUANTIFY {
    tag "RSEM_QUANTIFY on ${pair_id}"
    label 'process_medium'
    container "chandiniv/star-rsem:1.0.1"
    publishDir "${params.results_dir}/rsem_expression", mode:'copy'

    input:
    val rsem_reference_dir
    tuple val(pair_id), path(bam_file)

    output:
    path "rsem_${pair_id}"

    script:
    """
    mkdir -p ./rsem_${pair_id}
    rsem-calculate-expression \
        --num-threads $task.cpus \
        --paired-end \
        --time \
        --no-bam-output \
        --alignments \
            ${bam_file} \
            ${rsem_reference_dir}/rsem \
            ./rsem_${pair_id}/rsem_${pair_id} >& \
            ./rsem_${pair_id}/rsem_${pair_id}.log

    """
}

process RSEM_QUANTIFY_SINGLE {
    tag "RSEM_QUANTIFY_SINGLE on ${bam_file}"
    label 'process_medium'
    container "chandiniv/star-rsem:1.0.1"
    publishDir "${params.results_dir}/rsem_expression", mode:'copy'

    input:
    val rsem_reference_dir
    path bam_file

    output:
    path "rsem_${bam_file.getName().substring(5,bam_file.getName().length()-31)}"

    script:
    """
    mkdir -p ./rsem_${bam_file.getName().substring(5,bam_file.getName().length()-31)}
    rsem-calculate-expression \
        --num-threads $task.cpus \
        --time \
        --no-bam-output \
        --alignments \
            ${bam_file} \
            ${rsem_reference_dir}/rsem \
            ./rsem_${bam_file.getName().substring(5,bam_file.getName().length()-31)}/rsem_${bam_file.getName().substring(5,bam_file.getName().length()-31)} >& \
            ./rsem_${bam_file.getName().substring(5,bam_file.getName().length()-31)}/rsem_${bam_file.getName().substring(5,bam_file.getName().length()-31)}.log

    """
}


process RSEM_SUMMARY {
    label 'process_low'
    container "chandiniv/star-rsem:1.0.1"
    publishDir params.results_dir, mode:'copy'

    input:
    path('*')

    output:
    path "rsem_summary" 

    script:
    """
    mkdir -p rsem_summary
    cd rsem_summary
    expression_summary.py  --expression-type rsem --input-path ..
    """
}

process GET_WORMBASE_DATA {
    label 'process_low'
    container "chandiniv/star-rsem:1.0.1"
    publishDir params.data_dir, mode:'copy'

    input:
    val wormbase_version

    output:
    path "wormbase", emit: wormbase_dir
    path "wormbase/c_elegans.PRJNA13758.${wormbase_version}.canonical_geneset.gtf", emit: annotation_file
    path "wormbase/c_elegans.PRJNA13758.${params.wormbase_version}.genomic.fa", emit: genome_file
    path "wormbase/c_elegans.PRJNA13758.${params.wormbase_version}.mRNA_transcripts.fa", emit: transcripts_file
    path "wormbase/c_elegans.PRJNA13758.${params.wormbase_version}.geneIDs.csv", emit: gene_ids

    script:
    """
    mkdir -p wormbase
    cd wormbase
    wormbase_download.sh ${wormbase_version}
    """
}

process PUBLISH_WORMBASE_GENE_IDS {
    label 'process_low'
    container "chandiniv/star-rsem:1.0.1"
    publishDir params.results_dir, mode:'copy'

    input:
    path gene_ids

    output:
    path gene_ids
    
    script:
    """
    echo ${gene_ids}
    """
}
