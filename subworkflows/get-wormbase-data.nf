
include { GET_WORMBASE_DATA         } from '../modules/rsem'
include { PUBLISH_WORMBASE_GENE_IDS } from '../modules/rsem'

workflow GET_WORMBASE_DATA_WF {
  take:
    wormbase_version
 
  main: 
     GET_WORMBASE_DATA(wormbase_version)
     PUBLISH_WORMBASE_GENE_IDS(GET_WORMBASE_DATA.out.gene_ids)
  emit: 
     annotation_file = GET_WORMBASE_DATA.out.annotation_file
     genome_file = GET_WORMBASE_DATA.out.genome_file
     transcripts_file = GET_WORMBASE_DATA.out.transcripts_file
     
}

