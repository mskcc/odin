process TMB {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://mskcc/helix_filters_01:23.9.0':
        'docker.io/mskcc/helix_filters_01:23.9.0' }"

    containerOptions "--bind $PWD"

    input:
    tuple val(meta), path(input_maf)

    output:
    tuple val(meta), path("*.tmb.tsv")                   , emit: tmb
    path "versions.yml"                                  , emit: versions

    script:
    task.ext.when == null || task.ext.when
    def argos_version = task.ext.argos_version ?: '1.5.0'
    def prefix = task.ext.prefix ?: "${meta.id}"
    def assay = "${meta.assay}".toUpperCase()
    def genome_coverage = params.impact_assay_info[assay]

    """
    python $PWD/bin/maf-filter/calc-tmb.py \\
        from-file \\
        ${input_maf} \\
        ${prefix}.tmb.tsv \\
        --genome-coverage ${genome_coverage} \\
        --tumor-id ${meta.tumorSampleName} \\
        --normal-id ${meta.normalSampleName}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        helix_filter_01: 21.4.1
    END_VERSIONS
    """
}
