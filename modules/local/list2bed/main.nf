process LIST2BED {


    tag "$meta.id"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://mskcc/list2bed:1.0.1':
        'docker.io/mskcc/list2bed:1.0.1' }"

    input:
    tuple val(meta), path(list_file)

    output:
    tuple val(meta), path("*.bed")  , emit: bed_file
    path "versions.yml"                , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def bed_file = "${prefix}.bed"

    """
    python /usr/bin/list2bed.py \\
        --input_file ${list_file} \\
        --output_file ${bed_file}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version 2>&1 | sed 's/Python //g')
        bedtools: \$(bedtools --version 2>&1 | sed 's/bedtools //g')
        list2bed: 1.0.1
    END_VERSIONS
    """
}
