process BCFTOOLS_CONCAT {


    tag "$meta.id"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://mskcc/htslib:1.9':
        'docker.io/mskcc/htslib:1.9' }"

    publishDir "${params.outdir}/${meta.id}/", pattern: "*.gz", mode: params.publish_dir_mode

    input:
    tuple val(meta), path(inputVcfs), path(inputVcfTbis)

    output:
    tuple val(meta), path("*.vcf.gz")  , emit: vcf
    path "versions.yml"                , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def input_vcfs = inputVcfs.join(" ")
    def output_vcf = "${prefix}.combined-variants.vcf.gz"
    """
    /usr/bin/bcftools concat \\
        ${input_vcfs} \\
        ${args} \\
        --output ${output_vcf}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: 1.9
        htslib: 1.9
    END_VERSIONS
    """

}
