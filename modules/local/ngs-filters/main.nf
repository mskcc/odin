process NGS_FILTERS {

    tag "$meta.id"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://mskcc/roslin-variant-ngs-filters:1.4':
        'docker.io/mskcc/roslin-variant-ngs-filters:1.4' }"

    publishDir "${params.outdir}/${meta.id}/", pattern: "*.maf", mode: params.publish_dir_mode

    input:
    tuple val(meta),  path(inputMaf)
    tuple val(meta2),  path(normalPanelMaf)

    output:
    tuple val(meta), path("*.maf")     , emit: maf
    path "versions.yml"                , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"


    """
    python /usr/bin/ngs-filters/run_ngs-filters.py \\
        ${args} \\
        --input-maf ${inputMaf} \\
        --normal-panel-maf ${normalPanelMaf} \\
        --output-maf ${prefix}.maf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version 2>&1 | sed 's/Python //g')
        ngs-filters: 1.4
        R: 3.5.1
    END_VERSIONS
    """

}
