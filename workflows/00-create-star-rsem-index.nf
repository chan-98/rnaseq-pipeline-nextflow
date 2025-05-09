#!/usr/bin/env nextflow 

nextflow.enable.dsl = 2

/*
 * Create STAR and rsem index files based on a specific Wormbase Release
 * NOTE: Pre-creation of the index will accelerate pipeline runs 
 */


log.info """\
 P A R A M S -- CREATE STAR RSEM INDEX 
 ============================================
 wormbase_version : ${params.wormbase_version}
 data_dir         : ${params.data_dir}
 results_dir      : ${params.results_dir}
 """

// import modules
include { GET_WORMBASE_DATA_WF } from '../subworkflows/get-wormbase-data'
include { RSEM_INDEX           } from '../modules/rsem'
include { STAR_INDEX           } from '../modules/star'


/* 
 * main script flow
 */
workflow CREATE_STAR_RSEM_INDEX {
  if(WorkflowUtils.directoryExists("${params.data_dir}/wormbase")){
    STAR_INDEX( params.genome_file, params.annotation_file )
    RSEM_INDEX( params.genome_file, params.annotation_file )
  }else{
    GET_WORMBASE_DATA_WF( params.wormbase_version )
    STAR_INDEX( GET_WORMBASE_DATA_WF.out.genome_file, GET_WORMBASE_DATA_WF.out.annotation_file )
    RSEM_INDEX( GET_WORMBASE_DATA_WF.out.genome_file, GET_WORMBASE_DATA_WF.out.annotation_file )
  }

}

workflow.onComplete {
	log.info ( workflow.success ? "\nDone! Index files can be found here --> ${params.results_dir}\n" : "Oops .. something went wrong" )
}
