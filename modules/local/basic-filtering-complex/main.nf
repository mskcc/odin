// https://github.com/mskcc/basicfiltering/releases/tag/0.3
// https://github.com/mskcc/basicfiltering

// there are three different scripts in the repo that are runnable; consider building image
//   with dependencies but putting filter scripts in this repo

process BASICFILTERING_COMPLEX {


    tag "$meta.id"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://mskcc/basic-filtering:0.3':
        'docker.io/mskcc/basic-filtering:0.3' }"

    publishDir "${params.outdir}/${meta.id}/", pattern: "*.gz", mode: params.publish_dir_mode
    publishDir "${params.outdir}/${meta.id}/", pattern: "*.tbi", mode: params.publish_dir_mode

    input:
    tuple val(meta), path(inputVcf), path(input), path(input_index)

    output:
    tuple val(meta), path("*.vcf.gz")     , emit: vcf
    tuple val(meta), path("*.tbi")     , emit: vcf_index
    path "versions.yml"                , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def output_vcf = prefix + '.complex_filtered.vcf'
    def assay = meta.assay;
    def nrm_noise = params.default_complex_nn
    def tm_noise = params.default_complex_tn
    if (assay.contains("IMPACT") || assay.contains("HemePACT")){
        nrm_noise = params.impact_complex_nn
        tm_noise = params.impact_complex_tn
    }


    """
    filter_complex.py \\
        ${args} \\
        --input-vcf ${inputVcf} \\
        --tumor-id ${meta.tumorSampleName} \\
        --normal-bam ${input[1]} \\
        --tumor-bam ${input[0]} \\
        --nrm-noise ${nrm_noise} \\
        --tum-noise ${tm_noise} \\
        --output-vcf ${output_vcf}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version 2>&1 | sed 's/Python //g')
        basic_filtering: 0.3
    END_VERSIONS
    """

}
