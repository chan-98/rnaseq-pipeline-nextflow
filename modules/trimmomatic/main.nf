
//http://www.usadellab.org/cms/uploads/supplementary/Trimmomatic/TrimmomaticManual_V0.32.pdf

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

process TRIMMOMATIC {
    label 'process_medium'
    tag "TRIMMOMATIC on $sample_id"
    container "chandiniv/picard-trimmomatic:1.0.1"

    input:
    tuple val(sample_id), path(reads)
    val data_root
    val dir_suffix

    script:
    """
    cp -r ${projectDir}/assests/adapters .
    trimmomatic.sh ${reads[0]} ${reads[1]} ${data_root} ${dir_suffix} ${params.trimmomatic_control}
    """

    output:
    path "trim_${dir_suffix}" 

}

process TRIMMOMATIC_SINGLE {
    label 'process_medium'
    tag "TRIMMOMATIC_SINGLE on ${reads.getName().split("\\.")[0]}"
    container "chandiniv/picard-trimmomatic:1.0.1"

    input:
    path reads
    val data_root
    val dir_suffix

    script:
    """
    cp -r ${projectDir}/assests/adapters .
    trimmomatic.sh ${reads} "" ${data_root} ${dir_suffix} ${params.trimmomatic_control}
    """

    output:
    path "trim_${dir_suffix}" 

}

process TRIMMOMATIC_AGGREGATE {
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

