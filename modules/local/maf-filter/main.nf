process MAF_FILTER {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://mskcc/mjolnir:0.1.0':
        'docker.io/mskcc/mjolnir:0.1.0' }"

    containerOptions "--bind $projectDir"

    input:
    tuple val(meta), path(input_maf)

    output:
    tuple val(meta), path("*.analysis.muts.maf")         , emit: analysis_maf
    tuple val(meta), path("*.rejected.muts.maf")         , emit: rejected_maf
    tuple val(meta), path("data_mutations_extended.txt") , emit: data_mutations_extended_txt
    path "versions.yml"                                  , emit: versions

    script:
    task.ext.when == null || task.ext.when
    def odin_version = task.ext.odin_version ?: workflow.manifest.version
    def version_str = "'odin: ${odin_version}'"
    def prefix = task.ext.prefix ?: "${meta.id}"
    def impact_assay = task.ext.impact_assay ?: false
    def is_impact = ""
    if ( impact_assay ) (
        is_impact = "--is-impact"
    )
    """
    python3 $projectDir/bin/maf-filter/maf_filter.py \\
        ${input_maf} \\
        --keep-rejects \\
        --rejected-file ${prefix}.rejected.muts.maf \\
        --analyst-file ${prefix}.analysis.muts.maf \\
        --portal-file data_mutations_extended.txt \\
        --version-string ${version_str} \\
        ${is_impact}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mjolnir: 0.1.0
    END_VERSIONS
    """
}
