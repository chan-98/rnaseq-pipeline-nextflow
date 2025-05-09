


/**********************************
Phred+33 Scores

Quality | Prob.       | Accuracy
 Score  | Score is    |    of 
        | Incorrect   | Base Call
====================================
   10   | 1 in 10     | 90%
   20   | 1 in 100    | 99%
   30   | 1 in 1,000  | 99.90%
   40   | 1 in 10,000 | 99.99%
*************************************/

process TRIM_GALORE {
    label 'process_medium'
    tag "TRIM_GALORE on $sample_id"
    container "chandiniv/picard-trimmomatic:1.0.1"

    input:
    tuple val(sample_id), path(reads)
    val data_root
    val dir_suffix

    output:
    path "trim_${dir_suffix}" 

    script:
    def cores = 1
    if (task.cpus) {
        if (task.cpus > 4) cores = 4
    }

    """
    trim_galore.sh ${reads[0]} ${reads[1]} ${data_root} ${dir_suffix} ${params.trim_galore_control}
    """
}

/**********************************
process TRIM_GALORE_SINGLE {
    label 'process_medium'
    tag "TRIM_GALORE_SINGLE on $meta.id"
    container "chandiniv/picard-trimmomatic:1.0.1"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*trimmed.fastq.gz") , emit: reads
    tuple val(meta), path("*report.txt")       , emit: log
    tuple val(meta), path("*html")             , emit: html

    script:
        """
        [ ! -f  ${prefix}.fastq.gz ] && ln -s $reads ${prefix}.fastq.gz
        trim_galore \\
            $args \\
            --cores $cores \\
            --gzip \\
            
            ${prefix}.fastq.gz
        
        """
}
**********************************/

process TRIM_GALORE_AGGREGATE {
    label 'process_low'
    container "chandiniv/picard-trimmomatic:1.0.1"
    publishDir params.results_dir, mode:'copy'

    input:
    path('*')

    script:
    """
    trimmomatic_aggregate.sh
    """
    
    output:
    path "trimmed" 

}
