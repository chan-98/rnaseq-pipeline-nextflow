
include { FASTQC; FASTQC_SINGLE } from '../modules/fastqc'
include { SALMON_QUANTIFY; SALMON_QUANTIFY_SINGLE; SALMON_SUMMARY } from '../modules/salmon'
include { TXIMPORT_COUNTS } from '../modules/de-seq-tools'

workflow RNASEQ_SALMON {
  take:
    salmon_index
    read_pairs_ch
    tx2gene
    counts_method
 
  main: 
    //FASTQC(read_pairs_ch)
    SALMON_QUANTIFY(salmon_index, read_pairs_ch)
    TXIMPORT_COUNTS(SALMON_QUANTIFY.out.collect(), tx2gene, counts_method)
  emit: 
     //SALMON_QUANTIFY.out | concat(FASTQC.out) | collect
     SALMON_QUANTIFY.out | collect
}

workflow RNASEQ_SALMON_SINGLE {
  take:
    salmon_index
    reads_ch
    tx2gene
    counts_method
 
  main: 
    //FASTQC_SINGLE(reads_ch)
    SALMON_QUANTIFY_SINGLE(salmon_index, reads_ch)
    TXIMPORT_COUNTS(SALMON_QUANTIFY_SINGLE.out.collect(), tx2gene, counts_method)
  emit: 
     //SALMON_QUANTIFY_SINGLE.out | concat(FASTQC_SINGLE.out) | collect
     SALMON_QUANTIFY_SINGLE.out | collect
}