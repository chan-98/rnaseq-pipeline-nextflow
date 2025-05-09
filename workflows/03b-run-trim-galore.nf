#!/usr/bin/env nextflow 

log.info """\
 P A R A M S -- RUN TRIMGALORE 
 ===================================
 fastq_paired : ${params.fastq_paired}
 fastq_single : ${params.fastq_single}
 data_for     : ${params.data_for}
 results_dir  : ${params.results_dir}
 """

// import modules
include { TRIM_GALORE           } from '../modules/trim-galore'
//include { TRIM_GALORE_SINGLE    } from '../modules/trim-galore'
include { TRIM_GALORE_AGGREGATE } from '../modules/trim-galore'

/* 
 * main script flow
 */
workflow RUN_TRIM_GALORE {
  if(params.fastq_paired) {
    read_pairs_ch = channel.fromFilePairs( params.fastq_paired, checkIfExists: true )
    dir_suffix = channel.fromList(WorkflowUtils.generateUUIDs(50))
    TRIM_GALORE( read_pairs_ch, "fastq", dir_suffix )
    TRIM_GALORE_AGGREGATE(TRIM_GALORE.out.collect() )
  }

//  if(params.fastq_single)  {
//    read_ch = channel.fromPath( params.fastq_single, checkIfExists: true ) 
//    dir_suffix = channel.fromList(WorkflowUtils.generateUUIDs(50))
//    TRIM_GALORE_SINGLE(read_ch, "fastq", dir_suffix )
//    TRIM_GALORE_AGGREGATE(TRIMMOMATIC_SINGLE.out.collect()  )
//  }

}

/* 
 * completion handler
 */
workflow.onComplete {
  def msg = """\
        Pipeline execution summary
        ---------------------------
        Completed at: ${workflow.complete}
        Duration    : ${workflow.duration}
        Success     : ${workflow.success}
        workDir     : ${workflow.workDir}
        exit status : ${workflow.exitStatus}
        """
        .stripIndent()

    sendMail(to: 'daniel.higgins@umassmed.edu', subject: 'TRIM_GALORE completed', body: msg)

	log.info ( workflow.success ? "\nDone! The results can be found in --> ${params.results_dir}/trimmed\n" : "Oops .. something went wrong" )
}
