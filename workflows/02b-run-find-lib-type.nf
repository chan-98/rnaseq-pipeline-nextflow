#!/usr/bin/env nextflow 

log.info """\
 P A R A M S -- RUN FIND_LIB_TYPE
 ===================================
 salmon_index_dir : ${params.salmon_index_dir}
 fastq_paired : ${params.fastq_paired}
 fastq_single : ${params.fastq_single}
 results_dir  : ${params.results_dir}
 """

// import modules
include { FIND_LIB_TYPE        } from '../modules/salmon'
include { FIND_LIB_TYPE_SINGLE } from '../modules/salmon'

/* 
 * Run Find Lib type on each of the Fastq files
 */

workflow RUN_FIND_LIB_TYPE{
  if(params.fastq_paired) {
    read_pairs_ch = channel.fromFilePairs( params.fastq_paired, checkIfExists: true ) 
    FIND_LIB_TYPE(params.salmon_index_dir, read_pairs_ch)
  } 

  if(params.fastq_single)  {
    read_ch = channel.fromPath( params.fastq_single, checkIfExists: true ) 
    FIND_LIB_TYPE_SINGLE(params.salmon_index_dir, read_ch)
  }
}

workflow.onComplete {
	log.info ( workflow.success ? "\nDone! Open the following report in your browser --> ${params.results_dir}/lib_type\n" : "Oops .. something went wrong" )
}
