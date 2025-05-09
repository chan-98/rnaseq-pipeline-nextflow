#!/usr/bin/env nextflow 

log.info """\
 P A R A M S -- RUN WORMCAT 
 ===================================
 deseq_up_down_dir : ${params.deseq_up_down_dir}
 results_dir       : ${params.results_dir}
 """

// import modules
include { WORMCAT_CSV } from '../modules/wormcat'

/* 
 * main script flow
 */
workflow RUN_WORMCAT { 
  csv_dir_ch = channel.fromPath( params.deseq_up_down_dir, type: 'dir' )
  WORMCAT_CSV( csv_dir_ch )
}

workflow.onComplete {
	log.info ( workflow.success ? "\nDone! Your output can be found here --> ${params.results_dir}\n" : "Oops .. something went wrong" )
}
