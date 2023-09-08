process BCFTOOLS_ANNOTATE {


    tag "$meta.id"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://mskcc/htslib:1.9':
        'docker.io/mskcc/htslib:1.9' }"

    input:
    tuple val(meta), path(inputVcf), path(inputVcfTbi), path(annotateVcf), path(annotateVcfTbis)

    output:
    tuple val(meta), path("*.vcf")  , emit: vcf
    path "versions.yml"                , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def output_vcf = prefix + ".annotate-variants.vcf"
    """
    /usr/bin/bcftools annotate \\
        ${args} \\
        --annotations ${annotateVcf} \\
        --output ${output_vcf} \\
        ${inputVcf}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: 1.9
        htslib: 1.9
    END_VERSIONS
    """

}
