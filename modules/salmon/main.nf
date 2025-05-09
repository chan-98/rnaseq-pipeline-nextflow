
process SALMON_INDEX {
    tag "$transcriptome.simpleName"
    label 'process_medium'
    container "chandiniv/salmon-kallisto:1.0.1"
    publishDir params.results_dir, mode:'copy'
    
    input:
    path transcriptome 

    output:
    path 'salmon_index' 

    script:
    """
    salmon index --threads $task.cpus -t $transcriptome -i salmon_index
    """
}

process SALMON_QUANTIFY_SINGLE  {
    tag "SALMON_QUANTIFY_SINGLE on ${reads.getName().split("\\.")[0]}"
    label 'process_medium'
    container "chandiniv/salmon-kallisto:1.0.1"
    publishDir "${params.results_dir}/salmon_expression", mode:'copy'

    input:
    path index 
    path reads 

    output:
    path "salmon_${reads.getName().split("\\.")[0]}"

    script:
    """
    salmon quant --gcBias --threads $task.cpus --libType=A -i $index -r ${reads} -o ./salmon_${reads.getName().split("\\.")[0]}
    """
}

process SALMON_QUANTIFY{
    tag "SALMON_QUANTIFY on $pair_id"
    label 'process_medium'
    container "chandiniv/salmon-kallisto:1.0.1"
    publishDir "${params.results_dir}/salmon_expression", mode:'copy'

    input:
    path index 
    tuple val(pair_id), path(reads) 

    output:
    path "salmon_${pair_id}"

    script:
    """
    salmon quant --gcBias --threads $task.cpus --libType=A -i $index -1 ${reads[0]} -2 ${reads[1]} -o ./salmon_${pair_id}
    """
}

process SALMON_SUMMARY {
    label 'process_low'
    // NOTE: expression_summary.py  requires panadas and star-rsem:1.0.1 has it installed
    container "chandiniv/star-rsem:1.0.1"
    publishDir params.results_dir, mode:'copy'

    input:
    path('*')

    output:
    path "salmon_summary" 

    script:
    """
    mkdir -p salmon_summary
    cd salmon_summary
    expression_summary.py --expression-type salmon --input-path ..
    """
}


process FIND_LIB_TYPE_SINGLE  {
    tag "FIND_LIB_TYPE_SINGLE on ${reads.getName().split("\\.")[0]}"
    label 'process_medium'
    container "chandiniv/salmon-kallisto:1.0.1"
    publishDir "${params.results_dir}/lib_type", mode:'copy'

    input:
    path index 
    path reads 

    output:
    path "lib_type_${reads.getName().split("\\.")[0]}"

    script:
    """
    salmon quant --skipQuant --geneMap ${params.annotation_file} --threads $task.cpus --libType=A -i $index -r ${reads} -o ./lib_type_${reads.getName().split("\\.")[0]}
    """
}

process FIND_LIB_TYPE{
    tag "FIND_LIB_TYPE on $pair_id"
    label 'process_medium'
    container "chandiniv/salmon-kallisto:1.0.1"
    publishDir "${params.results_dir}/lib_type", mode:'copy'

    input:
    path index 
    tuple val(pair_id), path(reads) 

    output:
    path "lib_type_${pair_id}"

    script:
    """
    salmon quant --skipQuant --geneMap ${params.annotation_file} --threads $task.cpus --libType=A -i $index -1 ${reads[0]} -2 ${reads[1]} -o ./lib_type_${pair_id}
    """
}


