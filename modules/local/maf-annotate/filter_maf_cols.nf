process ANNOTATE_FILTER_MAF_COLS {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://mskcc/mjolnir:latest':
        'docker.io/mskcc/mjolnir:latest' }"

    containerOptions "--bind $projectDir"

    input:
    tuple val(meta), path(input_maf)

    output:
    tuple val(meta), path("*.muts.share.maf")         , emit: output_maf
    path "versions.yml"                               , emit: versions

    script:
    task.ext.when == null || task.ext.when
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    python $projectDir/bin/maf-filter/maf_col_filter.py \\
        ${input_maf} \\
        ${prefix}.muts.share.maf


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mjolnir: latest
    END_VERSIONS
    """
}
