process TMB {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://mskcc/mjolnir:0.1.0':
        'docker.io/mskcc/mjolnir:0.1.0' }"

    publishDir "${params.outdir}/${meta.id}/", pattern: "*.tsv", mode: params.publish_dir_mode

    input:
    tuple val(meta), path(input_maf)

    output:
    tuple val(meta), path("*.tmb.tsv")                   , emit: tmb
    path "versions.yml"                                  , emit: versions

    script:
    task.ext.when == null || task.ext.when
    def argos_version = task.ext.argos_version ?: '1.5.0'
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    calc-tmb.py \\
        --maf_file \\
        ${input_maf} \\
        --output_filename \\
        ${prefix}.tmb.tsv \\
        --tumorId ${meta.tumorSampleName} \\
        --assay  ${meta.assay.toUpperCase()} \\
        --normalType ${meta.normalType.toUpperCase()}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        odin-tmb: 1.0
    END_VERSIONS
    """
}
