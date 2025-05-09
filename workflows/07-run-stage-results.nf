#!/usr/bin/env nextflow 


log.info """\
 P A R A M S -- RUN OVERVIEW REPORT
 ===================================
 report_config : ${params.report_config}
 results_dir   : ${params.results_dir}
 data_dir      : ${params.data_dir}
 """

// import modules
include { OVERVIEW_REPORT } from '../modules/fastqc'
include { STAGE_RESULTS   } from '../modules/fastqc'

/* 
 * main script flow
 */
workflow RUN_STAGE_RESULTS { 
  report_config_ch = channel.fromPath( params.report_config, checkIfExists: true ) 
  stage_dir_ch = channel.value( WorkflowUtils.getStageDirName() ) 
  //stage_dir_ch = channel.value( "Results_dir" ) 
  OVERVIEW_REPORT( report_config_ch )
  STAGE_RESULTS(params.results_dir, params.data_dir, stage_dir_ch, OVERVIEW_REPORT.out)
}

workflow.onComplete {
	log.info ( workflow.success ? "\nDone! Open the following report in your browser --> ${params.results_dir}/overview_report.pdf\n" : "Oops .. something went wrong" )
}
