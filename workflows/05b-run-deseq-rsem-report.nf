#!/usr/bin/env nextflow 

log.info """\
 P A R A M S -- RUN DESEQ REPORT
 ===================================
 report_config : ${params.report_config}
 results_dir   : ${params.results_dir}
 """

// import modules
include { DESEQ_REPORT } from '../modules/fastqc'

/* 
 * main script flow
 */
workflow RUN_DESEQ_RSEM_REPORT { 
  report_config_ch = channel.fromPath( params.report_config, checkIfExists: true ) 
  DESEQ_REPORT( report_config_ch , params.results_dir)
}

workflow.onComplete {
	log.info ( workflow.success ? "\nDone! Open the following report in your browser --> ${params.results_dir}/deseq_report.pdf\n" : "Oops .. something went wrong" )
}