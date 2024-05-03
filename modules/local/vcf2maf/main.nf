// https://github.com/mskcc/basicfiltering/releases/tag/0.3
// https://github.com/mskcc/basicfiltering

// there are three different scripts in the repo that are runnable; consider building image
//   with dependencies but putting filter scripts in this repo

process VCF2MAF {


    tag "$meta.id"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://mskcc/vcf2maf:1.6.17':
        'docker.io/mskcc/vcf2maf:1.6.17' }"

    input:
    tuple val(meta),  path(inputVcf)
    tuple val(meta2), path(fasta)
    tuple val(meta3), path(fai)
    tuple val(meta4), path(exac_filter)
    tuple val(meta5), path(exac_filter_tbi)

    output:
    tuple val(meta), path("*.maf")     , emit: maf
    path "versions.yml"                , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def forks = task.cpus * 2

    """
    perl /usr/bin/vcf2maf/vcf2maf.pl \\
        ${args} \\
        --input-vcf ${inputVcf} \\
        --ref-fasta ${fasta} \\
        --vcf-tumor-id ${meta.tumorSampleName} \\
        --tumor-id ${meta.tumorSampleName} \\
        --vcf-normal-id ${meta.normalSampleName} \\
        --normal-id ${meta.normalSampleName} \\
        --filter-vcf ${exac_filter} \\
        --vep-forks ${forks} \\
        --output-maf ${prefix}.maf


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        perl: \$(perl -v | head -n 2 | grep -o '(v.*)' | sed 's/[()]//g')
        vcf2maf: 1.6.17
        VEP: 86
        htslib: 1.9
        samtools: 1.9
        bcftools: 1.9
    END_VERSIONS
    """

}
