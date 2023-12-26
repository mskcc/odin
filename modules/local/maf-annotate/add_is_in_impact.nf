process ANNOTATE_ADD_IS_IN_IMPACT {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://mskcc/mjolnir:0.1.0':
        'docker.io/mskcc/mjolnir:0.1.0' }"

    containerOptions "--bind $projectDir"

    publishDir "${params.outdir}/${meta.id}/", pattern: "${meta.id}.*", mode: params.publish_dir_mode

    input:
    tuple val(meta), path(input_maf)
    tuple val(meta2), path(impact_gene_list)

    output:
    tuple val(meta), path("*.muts.maf")         , emit: output_maf
    path "versions.yml"                         , emit: versions

    script:
    task.ext.when == null || task.ext.when
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    python3 $projectDir/bin/maf-filter/add_is_in_impact.py \\
        --input_file ${input_maf} \\
        --output_file ${prefix}.muts.maf \\
        --IMPACT_file ${impact_gene_list}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mjolnir: 0.1.0
    END_VERSIONS
    """
}
