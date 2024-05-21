process ANNOTATE_ADD_AF {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://mskcc/mjolnir:0.1.0':
        'docker.io/mskcc/mjolnir:0.1.0' }"

    publishDir "${params.outdir}/${meta.id}/", pattern: "*.maf", mode: params.publish_dir_mode

    input:
    tuple val(meta), path(input_maf)

    output:
    tuple val(meta), path("*.muts.maf")         , emit: output_maf
    path "versions.yml"                         , emit: versions

    script:
    task.ext.when == null || task.ext.when
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    add_af.py \\
        ${input_maf} \\
        ${prefix}_add_af.muts.maf


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mjolnir: 0.1.0
    END_VERSIONS
    """
}
