process GATK_FINDCOVEREDINTERVALS {


    tag "$meta.id"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://mskcc/gatk:3.3-0':
        'docker.io/mskcc/gatk:3.3-0' }"

    input:
    tuple val(meta), path(bams), path(bais)
    tuple val(meta2), path(fasta)
    tuple val(meta3), path(fasta_fai)
    each interval

    output:
    tuple val(meta), path("*fci")  , emit: fci
    path "versions.yml"                , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def bam_list = bams.join(" --input_file ")
    def output_interval = prefix + "_" + interval.join("_") + ".fci"
    def interval_list = interval.join(" --intervals ")

    """
    mkdir -p tmp
    java -Xms${task.memory.toMega()/4}m \\
        -Xmx${task.memory.toGiga()}g \\
        -XX:-UseGCOverheadLimit \\
        -Djava.io.tmpdir=./tmp \\
        -jar /usr/bin/gatk.jar \\
        -T FindCoveredIntervals \\
        --reference_sequence ${fasta} \\
        ${args} \\
        --intervals ${interval_list} \\
        --input_file ${bam_list} \\
        --out ${output_interval}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk: 3.3-0
    END_VERSIONS
    """
}
