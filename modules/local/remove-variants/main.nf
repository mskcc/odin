process REMOVE_VARIANTS {

    // Repo for remove_variants.py
    //      https://github.com/mskcc/remove-variants
    //
    // Location of Dockerfile:
    //      https://github.com/mskcc/roslin-variant/blob/2.6.x/build/containers/remove-variants/0.1.1/Dockerfile
    //

    tag "$meta.id"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://mskcc/remove-variants:0.1.1':
        'docker.io/mskcc/remove-variants:0.1.1' }"

    publishDir "${params.outdir}/${meta.id}/", pattern: "*.maf", mode: params.publish_dir_mode

    input:
    tuple val(meta),  path(inputMaf)

    output:
    tuple val(meta), path("*.maf")     , emit: maf
    path "versions.yml"                , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    python /usr/bin/remove_variants.py \\
        --input-maf ${inputMaf} \\
        --output-maf ${prefix}.rmv.maf


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version 2>&1 | sed 's/Python //g')
        remove-variants: 0.1.1
    END_VERSIONS
    """

}
