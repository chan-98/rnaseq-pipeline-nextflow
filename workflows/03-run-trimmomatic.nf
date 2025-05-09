#!/usr/bin/env nextflow 

log.info """\
 P A R A M S -- RUN TRIMMOMATIC 
 ===================================
 fastq_paired : ${params.fastq_paired}
 fastq_single : ${params.fastq_single}
 data_for     : ${params.data_for}
 results_dir  : ${params.results_dir}
 """

// import modules
include { TRIMMOMATIC           } from '../modules/trimmomatic'
include { TRIMMOMATIC_SINGLE    } from '../modules/trimmomatic'
include { TRIMMOMATIC_AGGREGATE } from '../modules/trimmomatic'

/* 
 * main script flow
 */
workflow RUN_TRIMMOMATIC {
  if(params.fastq_paired) {
    read_pairs_ch = channel.fromFilePairs( params.fastq_paired, checkIfExists: true )
    dir_suffix = channel.fromList(WorkflowUtils.generateUUIDs(50))
    TRIMMOMATIC( read_pairs_ch, "fastq", dir_suffix )
    TRIMMOMATIC_AGGREGATE(TRIMMOMATIC.out.collect() )
  }

  if(params.fastq_single)  {
    read_ch = channel.fromPath( params.fastq_single, checkIfExists: true ) 
    dir_suffix = channel.fromList(WorkflowUtils.generateUUIDs(50))
    TRIMMOMATIC_SINGLE(read_ch, "fastq", dir_suffix )
    TRIMMOMATIC_AGGREGATE(TRIMMOMATIC_SINGLE.out.collect()  )
  }

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

    sendMail(to: 'daniel.higgins@umassmed.edu', subject: 'TRIMMOMATIC completed', body: msg)

	log.info ( workflow.success ? "\nDone! The results can be found in --> ${params.results_dir}/trimmed\n" : "Oops .. something went wrong" )
}
