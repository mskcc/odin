process MUTECT {
    tag "$meta.id"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://mskcc/roslin-variant-mutect:1.1.4':
        'docker.io/mskcc/roslin-variant-mutect:1.1.4' }"

    publishDir "${params.outdir}/${meta.id}/", pattern: "*.vcf", mode: params.publish_dir_mode

    input:
    tuple val(meta), path(input), path(input_index), path(intervals)
    tuple val(meta2), path(fasta)
    tuple val(meta3), path(fai)
    tuple val(meta4), path(dbsnp)
    tuple val(meta5), path(cosmic)

    output:
    tuple val(meta), path("*.vcf")     , emit: vcf
    tuple val(meta), path("*.txt")     , emit: stats
    path "versions.yml"                , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    mkdir -p tmp
    java -Xms${task.memory.toMega()/4}m \\
        -Xmx${task.memory.toGiga()}g \\
        -XX:-UseGCOverheadLimit \\
        -Djava.io.tmpdir=./tmp \\
        -jar /usr/bin/mutect.jar \\
        --reference_sequence ${fasta} \\
        --dbsnp ${dbsnp} \\
        --cosmic ${cosmic} \\
        --input_file:tumor ${input[0]} \\
        --input_file:normal ${input[1]} \\
        --intervals ${intervals} \\
        ${args} \\
        --vcf ${prefix}.mutect.vcf \\
        --out ${prefix}.mutect.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mutect: 1.1.4
    END_VERSIONS
    """
}
