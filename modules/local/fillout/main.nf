process FILLOUT {


    tag "$meta.id"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://mskcc/roslin-variant-cmo-utils:1.9.15':
        'docker.io/mskcc/roslin-variant-cmo-utils:1.9.15' }"

    publishDir "${params.outdir}/${meta.id}/", pattern: "*.fillout", mode: params.publish_dir_mode
    publishDir "${params.outdir}/${meta.id}/", pattern: "*.maf", mode: params.publish_dir_mode

    input:
    tuple val(meta),   path(inputMaf), path(bams), path(bais)
    tuple val(meta3),  path(fasta)
    tuple val(meta4),  path(fai)
    val(curated_bams)

    output:
    tuple val(meta), path("*.fillout")     , emit: fillout
    tuple val(meta), path("*.maf")         , emit: maf
    path "versions.yml"                    , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def pair_file_contents = "${meta.normalSampleName}\t${meta.tumorSampleName}"
    def pair_file_name = "tn_pairing_file.txt"
    def extra_args = ""
    if(curated_bams == true){
        output = inputMaf.baseName.replaceAll('maf$','')
        extra_args = "--output ${output}.curated.fillout"
    }
    else{
        extra_args = "--pairing-file ${pair_file_name}"
    }

    """
    echo "${pair_file_contents}" > "${pair_file_name}"
    fillout.py \\
        --n_threads ${task.cpus} \\
        ${args} \\
        ${extra_args} \\
        --maf ${inputMaf} \\
        --bams ${bams} \\
        --ref-fasta ${fasta}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version 2>&1 | sed 's/Python //g')
        cmo: 1.9.15
        picard: 2.9
        samtools: 1.9
        htslib: 1.9
        getBaseCountsMultiSample: 1.2.2
    END_VERSIONS
    """

}
