
include { MUTECT } from '../../../modules/local/mutect/main'
include { VARDICTJAVA } from '../../../modules/local/vardictjava/main'
include { BASICFILTERING_MUTECT } from '../../../modules/local/basic-filtering-mutect/main'
include { BASICFILTERING_VARDICT } from '../../../modules/local/basic-filtering-vardict/main'
include { BASICFILTERING_COMPLEX } from '../../../modules/local/basic-filtering-complex/main'
include { BCFTOOLS_CONCAT } from '../../../modules/local/bcftools-concat/main'
include { TABIX } from '../../../modules/local/tabix/main'
include { BCFTOOLS_ANNOTATE } from '../../../modules/local/bcftools-annotate/main'

workflow CALL_VARIANTS {

    take:
    ch_bams           // meta, path bams, path bais, path bed
    ch_bedfile        // bedfile path
    ch_fasta_ref      // fasta path
    ch_fasta_fai_ref  // fasta_fai path
    ch_dbsnp          // dbsnp path
    ch_cosmic         // cosmic path
    ch_hotspot        // hotspot path


    main:
    ch_versions = Channel.empty()
    vc_input = Channel.empty()

    ch_bams
        .combine(ch_bedfile)
        .set{ vc_input }

    vc_input.view()
    ch_fasta_ref.view()
    ch_fasta_fai_ref.view()

    MUTECT (
        vc_input,
        ch_fasta_ref,
        ch_fasta_fai_ref,
        ch_dbsnp,
        ch_cosmic
    )
    ch_versions = ch_versions.mix(MUTECT.out.versions)

    VARDICTJAVA (
        vc_input,
        ch_fasta_ref,
        ch_fasta_fai_ref
    )

    ch_versions = ch_versions.mix(VARDICTJAVA.out.versions)

    BASICFILTERING_MUTECT (
        MUTECT.out.vcf,
        MUTECT.out.stats,
        ch_hotspot,
        ch_fasta_ref,
        ch_fasta_fai_ref
    )

    ch_versions = ch_versions.mix(BASICFILTERING_MUTECT.out.versions)

    BASICFILTERING_VARDICT (
        VARDICTJAVA.out.vcf,
        ch_hotspot,
        ch_fasta_ref,
        ch_fasta_fai_ref
    )

    ch_versions = ch_versions.mix(BASICFILTERING_VARDICT.out.versions)

    BASICFILTERING_COMPLEX (
        vc_input,
        VARDICTJAVA.out.vcf
    )

    ch_versions = ch_versions.mix(BASICFILTERING_COMPLEX.out.versions)


    vcf_filtered_group = Channel.empty()
    vcf_indexed_group = Channel.empty()
    vcf_filtered = Channel.empty()
    vcf_indexed = Channel.empty()
    BASICFILTERING_MUTECT.out.vcf
        .join(BASICFILTERING_VARDICT.out.vcf)
        .join(BASICFILTERING_COMPLEX.out.vcf)
        .set{vcf_filtered_group}

    vcf_filtered_group
        .map{
        new Tuple(it[0],[it[1],it[2],it[3]])
        }
        .set{vcf_filtered}

    BASICFILTERING_MUTECT.out.vcf_index
        .join(BASICFILTERING_VARDICT.out.vcf_index)
        .join(BASICFILTERING_COMPLEX.out.vcf_index)
        .set{vcf_indexed_group}

    vcf_indexed_group
        .map{
        new Tuple(it[0],[it[1],it[2],it[3]])
        }
        .set{vcf_indexed}


    BCFTOOLS_CONCAT (
        vcf_filtered,
        vcf_indexed
    )

    ch_versions = ch_versions.mix(BCFTOOLS_CONCAT.out.versions)

    TABIX (
        BCFTOOLS_CONCAT.out.vcf
    )

    ch_versions = ch_versions.mix(TABIX.out.versions)

    BCFTOOLS_ANNOTATE (
        BCFTOOLS_CONCAT.out.vcf,
        TABIX.out.vcf_index,
        BASICFILTERING_VARDICT.out.vcf,
        BASICFILTERING_VARDICT.out.vcf_index
    )

    ch_versions = ch_versions.mix(BCFTOOLS_ANNOTATE.out.versions)




    emit:
    vardict_vcf = VARDICTJAVA.out.vcf
    mutect_vcf = MUTECT.out.vcf
    mutect_stats = MUTECT.out.stats
    mutect_filter_vcf = BASICFILTERING_MUTECT.out.vcf
    mutect_filter_vcf_index = BASICFILTERING_MUTECT.out.vcf_index
    vardict_filter_vcf = BASICFILTERING_VARDICT.out.vcf
    vardict_filter_vcf_index = BASICFILTERING_VARDICT.out.vcf_index
    complex_filter_vcf = BASICFILTERING_COMPLEX.out.vcf
    complex_filter_vcf_index = BASICFILTERING_COMPLEX.out.vcf_index
    combine_vcf = BCFTOOLS_CONCAT.out.vcf
    combine_vcf_index = TABIX.out.vcf_index
    annotate_vcf = BCFTOOLS_ANNOTATE.out.vcf
    versions = ch_versions

}
