process ANNOTATE_ADD_MAF_COMMENT {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://mskcc/mjolnir:latest':
        'docker.io/mskcc/mjolnir:latest' }"

    containerOptions "--bind $projectDir"

    input:
    tuple val(meta), path(input_maf)

    output:
    tuple val(meta), path("*.muts.maf")         , emit: output_maf
    path "versions.yml"                         , emit: versions

    script:
    task.ext.when == null || task.ext.when
    def odin_version = params.raw_input_workflow_version ?: "stand-alone"
    def prefix = task.ext.prefix ?: "${meta.id}"
    def comment_label = "raw_input_workflow"
    def comment_value = odin_version

    """
    $projectDir/bin/maf-filter/concat_with_comments.sh \\
        ${comment_label} \\
        ${comment_value} \\
        ${prefix}_add_maf_comment.muts.maf \\
        ${input_maf}


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mjolnir: latest
    END_VERSIONS
    """
}
