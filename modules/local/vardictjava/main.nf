process VARDICTJAVA {
    tag "$meta.id"
    label 'process_high'

    conda "bioconda::vardict-java=1.5.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://mskcc/roslin-variant-vardict:1.5.1':
        'docker.io/mskcc/roslin-variant-vardict:1.5.1' }"

    input:
    tuple val(meta), path(bams), path(bais), path(bed)
    tuple val(meta2), path(fasta)
    tuple val(meta3), path(fasta_fai)

    output:
    tuple val(meta), path("*.vcf"), emit: vcf
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args
    def args2 = task.ext.args2 ?: ''
    def prefix = bams[0].getSimpleName() +"." + bams[1].getSimpleName()

    def somatic = true  // this is unused here, but TODO: set this up to be as similar to nf-core vardictjava as possible
    def input = "-b \"${bams[0]}|${bams[1]}\""
    def var2vcf_input = "-N \"${meta.tumorSampleName}|${meta.normalSampleName}\""
    def filter = "/usr/bin/vardict/testsomatic.R"
    def convert_to_vcf = "/usr/bin/vardict/var2vcf_paired.pl"
    """
    /usr/bin/vardict/bin/VarDict \\
        ${args} \\
        ${input} \\
        -th ${task.cpus} \\
        -G ${fasta} \\
        ${bed} \\
    | Rscript ${filter} \\
    | perl ${convert_to_vcf} \\
        ${var2vcf_input} \\
        ${args2} \\
    > ${prefix}.vcf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        vardict: 1.5.1
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: '-c 1 -S 2 -E 3'
    def args2 = task.ext.args2 ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch ${prefix}.vcf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        vardict-java: \$( realpath \$( command -v vardict-java ) | sed 's/.*java-//;s/-.*//' )
        var2vcf_valid.pl: \$( var2vcf_valid.pl -h | sed '2!d;s/.* //' )
    END_VERSIONS
    """
}
