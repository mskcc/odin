process CAT {


    tag "$meta.id"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://mskcc/alpine:3.8':
        'docker.io/mskcc/alpine:3.8' }"

    input:
    tuple val(meta), val(output_file), path(files)

    output:
    tuple val(meta), path(output_file)  , emit: combined
    path "versions.yml"                , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def file_list =files.join(" ")

    """

    cat ${file_list} > ${output_file}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cat: BusyBox v1.28.4
    END_VERSIONS
    """
}
