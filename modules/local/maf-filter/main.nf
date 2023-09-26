process MAF_FILTER {
    tag "$meta.id"
    label 'process_small'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://mskcc/helix_filters_01:21.4.1':
        'docker.io/mskcc/helix_filters_01:21.4.1' }"

    input:
    tuple val(meta), path(input_maf)

    output:
    tuple val(meta), path("*.analysis.muts.maf")         , emit: analysis_maf
    tuple val(meta), path("*.rejected.muts.maf")         , emit: rejected_maf
    tuple val(meta), path("data_mutations_extended.txt") , emit: data_mutations_extended_txt
    path "versions.yml"                                  , emit: versions

    script:
    task.ext.when == null || task.ext.when
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    python $PWD/bin/maf-filter/maf_filter.py \\
        ${input_maf} \\
        --keep-rejects \\
        --rejected-file ${prefix}.rejected.muts.maf \\
        --analyst-file ${prefix}.analysis.muts.maf \\
        --portal-file data_mutations_extended.txt 

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        helix_filter_01: 21.4.1
    END_VERSIONS
    """
}