// https://github.com/mskcc/basicfiltering/releases/tag/0.3
// https://github.com/mskcc/basicfiltering

// there are three different scripts in the repo that are runnable; consider building image
//   with dependencies but putting filter scripts in this repo

process BASICFILTERING_VARDICT {


    tag "$meta.id"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://mskcc/basic-filtering:0.3':
        'docker.io/mskcc/basic-filtering:0.3' }"

    publishDir "${params.outdir}/${meta.id}/", pattern: "*.gz", mode: params.publish_dir_mode
    publishDir "${params.outdir}/${meta.id}/", pattern: "*.tbi", mode: params.publish_dir_mode

    input:
    tuple val(meta),  path(inputVcf)
    tuple val(meta2), path(hotspotVcf)
    tuple val(meta3), path(fasta)
    tuple val(meta4), path(fai)

    output:
    tuple val(meta), path("*.vcf.gz")     , emit: vcf
    tuple val(meta), path("*.tbi")     , emit: vcf_index
    path "versions.yml"                , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    filter_vardict.py \\
        ${args} \\
        --inputVcf ${inputVcf} \\
        --tsampleName ${meta.tumorSampleName} \\
        --hotspotVcf ${hotspotVcf} \\
        --refFasta ${fasta}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version 2>&1 | sed 's/Python //g')
        basic_filtering: 0.3
    END_VERSIONS
    """

}
