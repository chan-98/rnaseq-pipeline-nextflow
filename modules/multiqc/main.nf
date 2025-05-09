
process MULTIQC {
    label 'process_medium'
    container 'chandiniv/qc-tools:1.0.1'
    publishDir params.results_dir, mode:'copy'

    input:
    val report_nm
    path('*')

    output:
    path(report_nm)

    script:
    """
    multiqc . --filename ${report_nm}
    """
}
