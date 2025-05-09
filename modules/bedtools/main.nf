
process DECOY_TRANSCRIPTOME {
    label 'process_low'
    container 'chandiniv/samtools-bedtools:1.0.1'
    publishDir params.results_dir, mode:'copy'

    input:
    path genome_file
    path annotation_file
    path transcripts_file

    output:
    path "salmon_transcripts/gentrome.fa", emit: gentrome_fa

    script:
    """
    generateDecoyTranscriptome.sh -j $task.cpus -a ${annotation_file} -g ${genome_file} -t ${transcripts_file} -o salmon_transcripts
    """
}
