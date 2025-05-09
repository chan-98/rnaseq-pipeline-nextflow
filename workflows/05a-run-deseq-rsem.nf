#!/usr/bin/env nextflow 


log.info """\
 P A R A M S -- RUN DESEQ RSEM
 ===================================
 deseq_meta    : ${params.deseq_meta}
 rsem_counts   : ${params.rsem_counts}
 low_count_max : ${params.low_count_max}
 results_dir   : ${params.results_dir}
 """

// import modules
include { LOW_COUNT_FILTER } from '../modules/de-seq-tools'
include { DESEQ_EXEC       } from '../modules/de-seq-tools'

/* 
 * main script flow
 */
workflow RUN_DESEQ_RSEM {
  counts_ch = channel.value( params.rsem_counts ) 
  deseq_meta_ch = channel.fromPath( params.deseq_meta, checkIfExists: true ) 
  LOW_COUNT_FILTER( counts_ch, params.low_count_max )
  DESEQ_EXEC( LOW_COUNT_FILTER.out.low_count_file, deseq_meta_ch )
}

workflow.onComplete {
	log.info ( workflow.success ? "\nDone! Open the following report in your browser --> ${params.results_dir}/multiqc_rsem_report.html\n" : "Oops .. something went wrong" )
}
