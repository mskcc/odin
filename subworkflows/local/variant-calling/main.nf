
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
    ch_fasta_ref      // fasta path
    ch_fasta_fai_ref  // fasta_fai path
    ch_dbsnp          // dbsnp path
    ch_cosmic         // cosmic path
    ch_hotspot        // hotspot path


    main:
    ch_versions = Channel.empty()

    MUTECT (
        ch_bams,
        ch_fasta_ref,
        ch_fasta_fai_ref,
        ch_dbsnp,
        ch_cosmic
    )
    ch_versions = ch_versions.mix(MUTECT.out.versions)

    VARDICTJAVA (
        ch_bams,
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

    vcf_and_bam = Channel.empty()
    vcf_and_bam = join_vcf_with_bams(VARDICTJAVA.out.vcf, ch_bams)

    BASICFILTERING_COMPLEX (
        vcf_and_bam
    )

    ch_versions = ch_versions.mix(BASICFILTERING_COMPLEX.out.versions)

    BASICFILTERING_VARDICT (
        BASICFILTERING_COMPLEX.out.vcf,
        ch_hotspot,
        ch_fasta_ref,
        ch_fasta_fai_ref
    )


    ch_versions = ch_versions.mix(BASICFILTERING_VARDICT.out.versions)






    all_vcf_files = join_vcf_files(BASICFILTERING_VARDICT.out.vcf,BASICFILTERING_MUTECT.out.vcf,BASICFILTERING_VARDICT.out.vcf_index, BASICFILTERING_MUTECT.out.vcf_index)


    BCFTOOLS_CONCAT (
        all_vcf_files
    )

    ch_versions = ch_versions.mix(BCFTOOLS_CONCAT.out.versions)

    TABIX (
        BCFTOOLS_CONCAT.out.vcf
    )

    ch_versions = ch_versions.mix(TABIX.out.versions)

    all_bcftools_input = join_bcftools_input(BCFTOOLS_CONCAT.out.vcf,TABIX.out.vcf_index,BASICFILTERING_MUTECT.out.vcf,BASICFILTERING_MUTECT.out.vcf_index)


    BCFTOOLS_ANNOTATE (
        all_bcftools_input
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

def join_vcf_with_bams(vcf,bams) {
        vcf_channel = vcf
            .map{
                new Tuple(it[0].id,it)
                }
        bams_channel = bams
            .map{
                new Tuple(it[0].id,it)
                }
        mergedWithKey = vcf_channel
            .join(bams_channel)
        merged = mergedWithKey
            .map{
                new Tuple(it[1][0],it[1][1],it[2][1],it[2][2])
            }
        return merged

}

def join_vcf_files(first_vcf, second_vcf, first_vcf_index, second_vcf_index) {
        first_vcf_channel = first_vcf
            .map{
                new Tuple(it[0].id,it)
                }
        second_vcf_channel = second_vcf
            .map{
                new Tuple(it[0].id,it)
                }
        first_vcf_index_channel = first_vcf_index
            .map{
                new Tuple(it[0].id,it)
                }
        second_vcf_index_channel = second_vcf_index
            .map{
                new Tuple(it[0].id,it)
                }
        merged = first_vcf_channel
            .join(second_vcf_channel)
            .join(first_vcf_index_channel)
            .join(second_vcf_index_channel)
            .map{
                new Tuple(it[1][0],[it[1][1],it[2][1]],[it[3][1],it[4][1]])
            }
        return merged
}

def join_bcftools_input(concat_vcf, concat_index_vcf,mutect_vcf, mutect_index_vcf) {
        concat_vcf_channel = concat_vcf
            .map{
                new Tuple(it[0].id,it)
                }
        concat_index_vcf_channel = concat_index_vcf
            .map{
                new Tuple(it[0].id,it)
                }
        mutect_vcf_channel = mutect_vcf
            .map{
                new Tuple(it[0].id,it)
                }
        mutect_index_vcf_channel = mutect_index_vcf
            .map{
                new Tuple(it[0].id,it)
                }
        merged = concat_vcf_channel
            .join(concat_index_vcf_channel)
            .join(mutect_vcf_channel)
            .join(mutect_index_vcf_channel)
            .map{
                new Tuple(it[1][0],it[1][1],it[2][1],it[3][1],it[4][1])
            }
        return merged



}
