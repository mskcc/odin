process ANNOTATE_ADD_AF {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://mskcc/helix_filters_01:23.9.0':
        'docker.io/mskcc/helix_filters_01:23.9.0' }"

    containerOptions "--bind $projectDir"

    input:
    tuple val(meta), path(input_maf)

    output:
    tuple val(meta), path("*.muts.maf")         , emit: output_maf
    path "versions.yml"                         , emit: versions

    script:
    task.ext.when == null || task.ext.when
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    python $projectDir/bin/maf-filter/add_af.py \\
        ${input_maf} \\
        ${prefix}_add_af.muts.maf


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        helix_filter_01: 21.4.1
    END_VERSIONS
    """
}
