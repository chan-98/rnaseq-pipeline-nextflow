
include { FASTQC; FASTQC_SINGLE } from '../modules/fastqc'
include { STAR_ALIGN; STAR_ALIGN_SINGLE } from '../modules/star'
include { RSEM_QUANTIFY; RSEM_QUANTIFY_SINGLE; RSEM_SUMMARY } from '../modules/rsem'

workflow RNASEQ_STAR_RSEM {
  take:
    star_index_dir
    rsem_reference_dir
    read_pairs_ch
 
  main: 
    //FASTQC(read_pairs_ch)
    STAR_ALIGN(star_index_dir, read_pairs_ch)
    RSEM_QUANTIFY(rsem_reference_dir,STAR_ALIGN.out.bam_file)
    RSEM_SUMMARY(RSEM_QUANTIFY.out.collect())
  emit: 
     //RSEM_QUANTIFY.out | concat(STAR_ALIGN.out.star_align_dir) | concat(FASTQC.out) |collect
     RSEM_QUANTIFY.out | concat(STAR_ALIGN.out.star_align_dir) |collect
}

workflow RNASEQ_STAR_RSEM_SINGLE {
  take:
    star_index_dir
    rsem_reference_dir
    read_ch
 
  main: 
    //FASTQC_SINGLE(read_ch)
    STAR_ALIGN_SINGLE(star_index_dir, read_ch)
    RSEM_QUANTIFY_SINGLE(rsem_reference_dir, STAR_ALIGN_SINGLE.out.bam_file)
    RSEM_SUMMARY(RSEM_QUANTIFY_SINGLE.out.collect())
  emit: 
     //RSEM_QUANTIFY_SINGLE.out | concat(STAR_ALIGN_SINGLE.out.star_align_dir) | concat(FASTQC_SINGLE.out) |collect
     RSEM_QUANTIFY_SINGLE.out | concat(STAR_ALIGN_SINGLE.out.star_align_dir)  |collect
}