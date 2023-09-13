process SAMTOOLS_HEADER_VIEW {


    tag "$meta.id"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://mskcc/htslib:1.9':
        'docker.io/mskcc/htslib:1.9' }"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), stdout  , emit: sample_name
    path "versions.yml"                , emit: versions

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def args3 = task.ext.args3 ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    /usr/local/bin/samtools \\
        ${args} \\
        ${bam} | grep -o '${args2}' | sed '${args3}'

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: 1.9
        htslib: 1.9
    END_VERSIONS
    """

}
